#!/usr/bin/env python3
import argparse
import base64
import json
import os
import re
from dataclasses import dataclass, asdict
from typing import Dict, List, Optional, Tuple

import yaml
from pykeepass import PyKeePass
from pykeepass.entry import Entry
from pykeepass.group import Group
from pathlib import Path

# ----------------------------
# Utilities
# ----------------------------

def remove_directory_tree(start_directory: str):
    """Recursively and permanently removes the specified directory, all of its
    subdirectories, and every file contained in any of those folders."""
    for name in os.listdir(start_directory):
        path = os.path.join(start_directory, name)
        if os.path.isfile(path):
            #print(f"Deleting the '{path}' file.")
            os.remove(path)
        else:
            remove_directory_tree(path)
    #print(f"Deleting the empty '{start_directory}' directory.")
    os.rmdir(start_directory)

DNS1123_LABEL = re.compile(r"^[a-z0-9]([-a-z0-9]*[a-z0-9])?$")


def b64(s: str) -> str:
    return base64.b64encode(s.encode("utf-8")).decode("ascii")


def slug_dns1123(name: str, max_len: int = 63) -> str:
    s = (name or "").strip().lower()
    s = re.sub(r"[^a-z0-9-]+", "-", s)
    s = re.sub(r"-+", "-", s).strip("-")
    if not s:
        s = "secret"
    s = s[:max_len].strip("-")
    if not DNS1123_LABEL.match(s):
        s = re.sub(r"^[^a-z0-9]+", "", s)
        s = re.sub(r"[^a-z0-9]+$", "", s)
        if not s or not DNS1123_LABEL.match(s):
            s = "secret"
    return s


def parse_kv_csv(s: str) -> Dict[str, str]:
    out: Dict[str, str] = {}
    for item in (s or "").split(","):
        item = item.strip()
        if not item:
            continue
        if "=" not in item:
            out[item] = ""
        else:
            k, v = item.split("=", 1)
            out[k.strip()] = v.strip()
    return out


def group_path_parts(group: Optional[Group]) -> List[str]:
    if group is None:
        return ["Root"]
    parts: List[str] = []
    g = group
    while g is not None:
        if g.name:
            parts.append(g.name)
        g = g.parentgroup  ### Hier passiert der Blödsinn
    return list(reversed(parts))


def get_custom_properties(entry: Entry) -> Dict[str, str]:
    props: Dict[str, str] = {}
    try:
        for k, v in (entry.custom_properties or {}).items():
            if v is None:
                continue
            props[str(k).strip()] = str(v)
    except Exception:
        pass
    return props


def namespace_from_folder(parts: List[str]) -> str:
    """
    Top-level group under root is namespace:
    ["Root", "prod", "payments"] -> "prod"
    """
    if len(parts) >= 2:
        return slug_dns1123(parts[1])
    return "default"


# ----------------------------
# OpenBao export model
# ----------------------------

@dataclass
class OpenBaoKVItem:
    mount: str  # e.g. "kv"
    key: str  # e.g. "k8s/prod/my-secret"
    data: Dict[str, str]  # plaintext fields


# ----------------------------
# Secret data extraction per type
# ----------------------------

def build_opaque(entry: Entry, props: Dict[str, str]) -> Tuple[str, Dict[str, str]]:
    data: Dict[str, str] = {}
    if entry.username:
        data["username"] = entry.username
    if entry.password:
        data["password"] = entry.password
    if entry.url:
        data["url"] = entry.url
    if entry.notes:
        data["notes"] = entry.notes

    # add non-control custom props as prop_*
    for k, v in props.items():
        if k.startswith(("k8s.", "eso.", "openbao.", "sa.", "docker.", "tls.")):
            continue
        safe_key = re.sub(r"[^A-Za-z0-9_.-]+", "_", k).strip("_")
        if safe_key:
            data[f"prop_{safe_key}"] = v

    return ("Opaque", data)


def build_tls(entry: Entry, props: Dict[str, str]) -> Tuple[str, Dict[str, str]]:
    data: Dict[str, str] = {}
    crt = props.get("tls.crt") or props.get("tls.cert")
    key = props.get("tls.key")
    ca = props.get("ca.crt")
    if not crt or not key:
        raise ValueError("tls requires custom properties tls.crt and tls.key")
    data["tls.crt"] = crt
    data["tls.key"] = key
    if ca:
        data["ca.crt"] = ca

    return ("kubernetes.io/tls", data)


def build_dockerconfigjson(entry: Entry, props: Dict[str, str]) -> Tuple[str, Dict[str, str]]:
    raw = props.get(".dockerconfigjson") or props.get("dockerconfigjson")
    if raw:
        # user-provided JSON string
        return ("kubernetes.io/dockerconfigjson", {".dockerconfigjson": raw})

    server = props.get("docker.server") or props.get("docker.registry")
    username = props.get("docker.username") or entry.username
    password = props.get("docker.password") or entry.password
    email = props.get("docker.email", "")

    if not server or not username or not password:
        raise ValueError("dockerconfigjson needs docker.server + docker.username/password (or entry username/password)")

    auth = b64(f"{username}:{password}")
    cfg = {
        "auths": {
            server: {
                "username": username,
                "password": password,
                "email": email,
                "auth": auth,
            }
        }
    }
    return ("kubernetes.io/dockerconfigjson", {".dockerconfigjson": json.dumps(cfg)})


def build_ssh(entry: Entry, props: Dict[str, str]) -> Tuple[str, Dict[str, str]]:
    key = props.get("ssh-privatekey") or props.get("ssh.key")
    if not key:
        raise ValueError("ssh requires custom property ssh-privatekey (or ssh.key)")
    pub = props.get("ssh-publickey") or props.get("ssh.publickey")
    if not pub:
        raise ValueError("ssh requires custom property ssh-publickey (or ssh.publickey)")
    return ("kubernetes.io/ssh-auth", {"ssh-publickey": pub, "ssh-privatekey": key})


def build_basic_auth(entry: Entry, props: Dict[str, str]) -> Tuple[str, Dict[str, str]]:
    username = props.get("username") or entry.username
    password = props.get("password") or entry.password
    if not username or not password:
        raise ValueError("basicauth needs username+password (from props or entry fields)")
    return ("kubernetes.io/basic-auth", {"username": username, "password": password})


def build_serviceaccount_token(entry: Entry, props: Dict[str, str]) -> Tuple[str, Dict[str, str], Dict[str, str]]:
    """
    NOTE: service-account-token secrets are populated by Kubernetes controllers, not by ESO.
    This generator can create an ExternalSecret, but it generally won't work as desired
    (token isn't a static secret in OpenBao). Usually better: TokenRequest or workload identity.
    Kept here only for completeness.
    """
    sa_name = props.get("sa.name")
    if not sa_name:
        raise ValueError("serviceaccounttoken needs custom property sa.name")
    # no data; the K8s controller would populate token fields
    extra_annotations = {"kubernetes.io/service-account.name": slug_dns1123(sa_name, 63)}
    return ("kubernetes.io/service-account-token", {}, extra_annotations)


# ----------------------------
# ExternalSecret manifest builder
# ----------------------------

def build_external_secret(
        name: str,
        namespace: str,
        store_name: str,
        store_kind: str,
        refresh_interval: str,
        target_secret_name: str,
        target_secret_type: str,
        labels: Dict[str, str],
        annotations: Dict[str, str],
        remote_key: str,
        fields: List[str],
        sync: str,
) -> Dict:
    """
    ESO ExternalSecret:
      data[] maps each K8s secretKey to remoteRef { key, property }.
    """
    if sync == "true":
        es = {
            "apiVersion": "secrets-store.csi.x-k8s.io/v1",
            "kind": "SecretProviderClass",
            "metadata": {
                "name": name,
                "namespace": namespace,
                "labels": labels,
                "annotations": annotations,
            },
            "spec": {
                "provider": "openbao", # 👈 Use "vault" if leveraging the existing Vault provider with OpenBao's Vault compatibility layer. Use "openbao" if using a native OpenBao provider.            
                "refreshInterval": refresh_interval,
                "secretStoreRef": {
                    "name": store_name,
                    "kind": store_kind,
                },
                "target": {
                    "name": target_secret_name,
                    "template": {
                        "type": target_secret_type,
                    },
                },
                "data": [
                    {
                        "secretKey": f,
                        "remoteRef": {
                            "key": remote_key,
                            "property": f,
                        },
                    }
                    for f in fields
                ],
            },
        }        
    else:
        es = {
            "apiVersion": "secrets-store.csi.x-k8s.io/v1",
            "kind": "SecretProviderClass",
            "metadata": {
                "name": name,
                "namespace": namespace,
                "labels": labels,
                "annotations": annotations,
            },
            "spec": {
                "provider": "openbao", # 👈 Use "vault" if leveraging the existing Vault provider with OpenBao's Vault compatibility layer. Use "openbao" if using a native OpenBao provider.            
                "refreshInterval": refresh_interval,
                "secretStoreRef": {
                    "name": store_name,
                    "kind": store_kind,
                },
                "target": {
                    "name": target_secret_name,
                    "template": {
                        "type": target_secret_type,
                    },
                },
                "data": [
                    {
                        "secretKey": f,
                        "remoteRef": {
                            "key": remote_key,
                            "property": f,
                        },
                    }
                    for f in fields
                ],
            },
        }

    return es

# ----------------------------
# K8SSecret manifest builder
# ----------------------------

def build_k8s_secret(
        name: str,
        namespace: str,
        target_secret_type: str,
        labels: Dict[str, str],
        annotations: Dict[str, str],
        data: Dict[str, str],
        fields: List[str],
) -> Dict:
    """
    ESO K8sSecret:
      data[] maps each K8s secretKey to remoteRef { key, property }.
    """
    secret_data = {
        f: b64(data[f])
        for f in fields
        if f in data  # nur wenn vorhanden
    }

    es = {
        "apiVersion": "v1",
        "kind": "Secret",
        "type": target_secret_type,
        "metadata": {
            "name": name,
            "namespace": namespace,
            "labels": labels,
            "annotations": annotations,
        },
        "data": secret_data,
    }
    return es


# ----------------------------
# Entry -> (ExternalSecret + OpenBao KV item)
# ----------------------------

def entry_to_outputs(
        entry: Entry,
        default_store_name: str,
        default_store_kind: str,
        default_refresh: str,
        default_mount: str,
        default_prefix: str,
        args_kdbx: str,
) -> Tuple[Optional[Dict], Optional[OpenBaoKVItem]]:
    props = get_custom_properties(entry)
    parts = group_path_parts(entry.group)

    ns = props.get("k8s.ns") or namespace_from_folder(parts)

    k8s_name_raw = props.get("k8s.name") or entry.title or "secret"
    k8s_name = slug_dns1123(k8s_name_raw)

    k8s_type = (props.get("k8s.type") or "opaque").strip().lower()
    k8s_output = (props.get("k8s.output") or "k8s").strip().lower()
    k8s_sync = (props.get("k8s.sync") or "false").strip().lower()

    store_name = (props.get("eso.store") or default_store_name).strip()
    store_kind = (props.get("eso.storeKind") or default_store_kind).strip()
    refresh = (props.get("eso.refresh") or default_refresh).strip()

    mount = (props.get("openbao.mount") or default_mount).strip()

    # remote key relative to mount
    default_key = f"{default_prefix.strip('/')}/{ns}/{k8s_name}".strip("/")
    remote_key_rel = (props.get("openbao.key") or default_key).strip().lstrip("/")
    remote_key = remote_key_rel  # ESO remoteRef.key typically uses full path relative to provider config

    labels = {"app.kubernetes.io/managed-by": slug_dns1123("keepass_to_eso_openbao.py", 63)}
    labels.update(parse_kv_csv(props.get("k8s.labels", "")))

    if k8s_output == "k8s":
        annotations = {
            "keepassxc.folderPath": slug_dns1123("/".join(parts), 63),
            "keepassxc.database": slug_dns1123(args_kdbx, 63),
        }
    elif k8s_output == "openbao":
        annotations = {
            "keepassxc.folderPath": slug_dns1123("/".join(parts), 63),
            "keepassxc.database": slug_dns1123(args_kdbx, 63),
            "openbao.mount": slug_dns1123(mount, 63),
            "openbao.key": slug_dns1123(remote_key_rel, 63),
        }
    annotations.update(parse_kv_csv(props.get("k8s.annotations", "")))

    # Build the data we will store in OpenBao (KV)
    secret_type: str
    data: Dict[str, str]
    extra_ann: Dict[str, str] = {}

    if k8s_type == "opaque":
        secret_type, data = build_opaque(entry, props)
    elif k8s_type == "tls":
        secret_type, data = build_tls(entry, props)
    elif k8s_type in ("dockerconfigjson", "docker", "registry"):
        secret_type, data = build_dockerconfigjson(entry, props)
    elif k8s_type == "ssh":
        secret_type, data = build_ssh(entry, props)
    elif k8s_type in ("basicauth", "basic-auth"):
        secret_type, data = build_basic_auth(entry, props)
    elif k8s_type in ("serviceaccounttoken", "service-account-token", "satoken"):
        secret_type, data, extra_ann = build_serviceaccount_token(entry, props)
    else:
        raise ValueError(f"Unknown k8s.type: {k8s_type}")

    annotations.update(extra_ann)

    # Fields: keys of KV data are also the secretKey names in ESO
    fields = list(data.keys())

    # For serviceaccount-token, fields may be empty -> still generate ExternalSecret? usually useless.
    # We'll generate it only if it has fields OR if user explicitly wants it (k8s.type=serviceaccounttoken)
    # Keeping: generate even with empty data, but warn via annotation.
    if k8s_type.startswith("service"):
        annotations["warning"] = "service-account-token is usually not static; consider TokenRequest/workload identity"

    if k8s_output == "k8s":
        external_secret = build_k8s_secret(
            name=k8s_name,  # name of ExternalSecret
            namespace=ns,
            target_secret_type=secret_type,
            labels=labels,
            annotations=annotations,
            data=data,
            fields=fields,
        )
    elif k8s_output == "openbao":
        external_secret = build_external_secret(
            name=k8s_name,  # name of ExternalSecret
            namespace=ns,
            store_name=store_name,
            store_kind=store_kind,
            refresh_interval=refresh,
            target_secret_name=k8s_name,  # name of resulting K8s Secret
            target_secret_type=secret_type,
            labels=labels,
            annotations=annotations,
            remote_key=remote_key,
            fields=fields,
            sync=k8s_sync
        )

    else:
        raise ValueError(f"Unknown k8s.outgput: {k8s_output}")

    return external_secret


# ----------------------------
# CLI
# ----------------------------

def main():
    ap = argparse.ArgumentParser(description="KeePassXC -> ExternalSecrets (ESO) + OpenBao KV export")
    ap.add_argument("--kdbx", required=True, help="Path to .kdbx")
    ap.add_argument("--password", help="Database password (or env KEEPASS_PASSWORD)")
    ap.add_argument("--keyfile", help="Optional keyfile path")

    ap.add_argument("--outdir", default="out", help="Output directory")

    # Defaults (the 'passt' assumptions)
    ap.add_argument("--store-name", default="secret/data")
    ap.add_argument("--store-kind", default="ClusterSecretStore", choices=["ClusterSecretStore", "SecretStore"])
    ap.add_argument("--refresh", default="1h")
    ap.add_argument("--mount", default="kv")
    ap.add_argument("--prefix", default="k8s")  # becomes k8s/<ns>/<name>

    ap.add_argument("--export-openbao", choices=["yaml", "json", "none"], default="yaml",
                    help="Export KV payloads for OpenBao as yaml/json plan (plaintext)")
    args = ap.parse_args()

    pw = args.password or os.environ.get("KEEPASS_PASSWORD")
    if not pw:
        raise SystemExit("Provide --password or env KEEPASS_PASSWORD")

    kp = PyKeePass(args.kdbx, password=pw, keyfile=args.keyfile)

    external_secrets: List[Dict] = []
    openbao_items: List[OpenBaoKVItem] = []
    errors: List[str] = []

    seen = set()  # (namespace, name) collisions
    for e in kp.entries:
        if getattr(e, "is_in_recycle_bin", False):
            continue
        if not (e.title or "").strip():
            continue

        try:
            es = entry_to_outputs(
                entry=e,
                default_store_name=args.store_name,
                default_store_kind=args.store_kind,
                default_refresh=args.refresh,
                default_mount=args.mount,
                default_prefix=args.prefix,
                args_kdbx=args.kdbx
            )
            ns = es["metadata"]["namespace"]
            name = es["metadata"]["name"]
            key = (ns, name)
            if key in seen:
                errors.append(f"Name collision: ExternalSecret {ns}/{name} derived from multiple entries")
                continue
            seen.add(key)

            external_secrets.append(es)
        except Exception as ex:
            gp = "/".join(group_path_parts(e.group))
            errors.append(f"{gp} :: {e.title}: {ex}")

    if os.path.exists(args.outdir):
        remove_directory_tree(args.outdir)
    else:
        None

    os.makedirs(args.outdir, exist_ok=True) # Recreate output dir
    with open(os.path.join(args.outdir,".gitignore"), "w", encoding="utf-8") as f:
        f.write("*" + "\n")


    # Write ExternalSecrets
    # es_dir = os.path.join(args.outdir, "external-secrets")
    es_dir = args.outdir
    # os.makedirs(es_dir, exist_ok=True)

    for es in external_secrets:
        ns = es["metadata"]["namespace"]
        name = es["metadata"]["name"]
        ns_dir = os.path.join(es_dir, ns)
        os.makedirs(ns_dir, exist_ok=True)
        outpath = os.path.join(ns_dir, f"{name}.yaml")
        with open(outpath, "w", encoding="utf-8") as f:
            yaml.safe_dump_all([es], f, sort_keys=False)

    # Write OpenBao export plan
    if args.export_openbao != "none":
        plan_path = os.path.join(args.outdir, f"openbao_kv_plan.{args.export_openbao}")
        if args.export_openbao == "yaml":
            with open(plan_path, "w", encoding="utf-8") as f:
                yaml.safe_dump([asdict(x) for x in openbao_items], f, sort_keys=False)
        else:
            with open(plan_path, "w", encoding="utf-8") as f:
                json.dump([asdict(x) for x in openbao_items], f, indent=2)
    else:
        plan_path = None

    # Write error report
    err_path = os.path.join(args.outdir, "errors.txt")
    if errors:
        with open(err_path, "w", encoding="utf-8") as f:
            f.write("\n".join(errors) + "\n")
    else:
        Path(err_path).unlink(missing_ok=True)

    print(f"Wrote {len(external_secrets)} ExternalSecrets to {es_dir}/")
    if plan_path:
        print(f"Wrote {len(openbao_items)} OpenBao KV items to {plan_path} (plaintext)")
    if errors:
        print(f"Wrote {len(errors)} errors to {os.path.join(args.outdir, 'errors.txt')}")


if __name__ == "__main__":
    main()
