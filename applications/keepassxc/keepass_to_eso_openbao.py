#!/usr/bin/env python3
import argparse
import base64
import datetime
from io import StringIO
import os
import re
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import json
from ruamel.yaml import YAML
from ruamel.yaml.scalarstring import LiteralScalarString

yaml = YAML()
yaml.indent(mapping=2, sequence=4, offset=2)

from pykeepass import PyKeePass
from pykeepass.entry import Entry
from pykeepass.group import Group


DNS1123_LABEL = re.compile(r"^[a-z0-9]([-a-z0-9]*[a-z0-9])?$")


def remove_directory_tree(start_directory: Path) -> None:
    """Recursively remove a directory tree."""
    if not start_directory.exists():
        return
    for child in start_directory.iterdir():
        if child.is_file() or child.is_symlink():
            child.unlink()
        else:
            remove_directory_tree(child)
    start_directory.rmdir()


def b64(value: str) -> str:
    return base64.b64encode(value.encode("utf-8")).decode("ascii")


def slug_dns1123(name: str, max_len: int = 63) -> str:
    slug = (name or "").strip().lower()
    slug = re.sub(r"[^a-z0-9-]+", "-", slug)
    slug = re.sub(r"-+", "-", slug).strip("-")
    if not slug:
        slug = "secret"
    slug = slug[:max_len].strip("-")
    if not DNS1123_LABEL.match(slug):
        slug = re.sub(r"^[^a-z0-9]+", "", slug)
        slug = re.sub(r"[^a-z0-9]+$", "", slug)
        if not slug or not DNS1123_LABEL.match(slug):
            slug = "secret"
    return slug


def parse_kv_csv(value: str) -> Dict[str, str]:
    parsed: Dict[str, str] = {}
    for item in (value or "").split(","):
        item = item.strip()
        if not item:
            continue
        if "=" not in item:
            parsed[item] = ""
        else:
            key, val = item.split("=", 1)
            parsed[key.strip()] = val.strip()
    return parsed


def group_path_parts(group: Optional[Group]) -> List[str]:
    if group is None:
        return ["Root"]
    parts: List[str] = []
    current = group
    while current is not None:
        if current.name:
            parts.append(current.name)
        current = current.parentgroup
    return list(reversed(parts))


def get_custom_properties(entry: Entry) -> Dict[str, str]:
    props: Dict[str, str] = {}
    try:
        for key, value in (entry.custom_properties or {}).items():
            if value is None:
                continue
            props[str(key).strip()] = str(value)
    except Exception:
        pass
    return props


def namespace_from_folder(parts: List[str]) -> str:
    if len(parts) >= 2:
        return slug_dns1123(parts[1])
    return "default"


class OpenBaoKVItem:
    def __init__(self, mount: str, key: str, data: Dict[str, str]) -> None:
        self.mount = mount
        self.key = key
        self.data = data


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

    for key, value in props.items():
        if key.startswith(("k8s.", "eso.", "openbao.", "sa.", "docker.", "tls.")):
            continue
        safe_key = re.sub(r"[^A-Za-z0-9_.-]+", "_", key).strip("_")
        if safe_key:
            data[f"prop_{safe_key}"] = value
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
    sa_name = props.get("sa.name")
    if not sa_name:
        raise ValueError("serviceaccounttoken needs custom property sa.name")
    extra_annotations = {"kubernetes.io/service-account.name": slug_dns1123(sa_name, 63)}
    return ("kubernetes.io/service-account-token", {}, extra_annotations)

def build_external_secret(
    name: str,
    namespace: str,
    target_secret_name: str,
    target_secret_type: str,
    labels: Dict[str, str],
    annotations: Dict[str, str],
    remote_key: str,
    fields: List[str],
    sync: str,
) -> Dict[str, Any]:
    
    fspec: Dict[str, Any] = [
            {
                "objectName": field, 
                "secretPath": f"secret/data/{remote_key}", 
                "secretKey": field,
            }
            for field in fields
        ]
    buf = StringIO()
    yaml.dump(fspec, buf)

    base_spec: Dict[str, Any] = {
        "provider": "openbao",
        "parameters": {
            "openbaoAddress": "http://openbao.openbao.svc:8200",
            "openbaoKVVersion": "2",
            "roleName": f"{namespace}-role",
            "objects": LiteralScalarString(buf.getvalue().rstrip()),
        },
    }
    if sync == "true":
        base_spec["secretObjects"] = [{
            "secretName": target_secret_name,
            "type": target_secret_type,
            "labels": {"managed-by": "openbao-csi"},
            "data": [
                {
                    "objectName": field,
                    "key": field,
                }
                for field in fields
            ],
        }]

    return {
        "apiVersion": "secrets-store.csi.x-k8s.io/v1",
        "kind": "SecretProviderClass",
        "metadata": {"name": name, "namespace": namespace, "labels": labels, "annotations": annotations},
        "spec": base_spec,
    }


def build_k8s_secret(
    name: str,
    namespace: str,
    target_secret_type: str,
    labels: Dict[str, str],
    annotations: Dict[str, str],
    data: Dict[str, str],
    fields: List[str],
) -> Dict[str, Any]:
    return {
        "apiVersion": "v1",
        "kind": "Secret",
        "type": target_secret_type,
        "metadata": {"name": name, "namespace": namespace, "labels": labels, "annotations": annotations},
        "data": {field: b64(data[field]) for field in fields if field in data},
    }


def entry_to_outputs(entry: Entry, default_mount: str, args_kdbx: str) -> Dict[str, Any]:
    props = get_custom_properties(entry)
    parts = group_path_parts(entry.group)

    namespace = props.get("k8s.ns") or namespace_from_folder(parts)
    k8s_name_raw = props.get("k8s.name") or entry.title or "secret"
    k8s_name = slug_dns1123(k8s_name_raw)

    k8s_type = (props.get("k8s.type") or "opaque").strip().lower()
    k8s_output = (props.get("k8s.output") or "k8s").strip().lower()
    k8s_sync = (props.get("k8s.sync") or "false").strip().lower()
    mount = (props.get("openbao.mount") or default_mount).strip()
    default_key = f"{namespace}/{k8s_name}".strip("/")
    remote_key_rel = (props.get("openbao.key") or default_key).strip().lstrip("/")

    labels = {"app.kubernetes.io/managed-by": "keepass-to-eso-openbao-py"}
    labels.update(parse_kv_csv(props.get("k8s.labels", "")))

    annotations = {
        "keepassxc.folderPath": slug_dns1123("/".join(parts), 63),
        "keepassxc.database": slug_dns1123(args_kdbx, 63),
    }
    if k8s_output == "openbao":
        annotations.update({
            "openbao.mount": slug_dns1123(mount, 63),
            "openbao.key": slug_dns1123(remote_key_rel, 63),
        })
    annotations.update(parse_kv_csv(props.get("k8s.annotations", "")))

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
        secret_type, data, extra_annotations = build_serviceaccount_token(entry, props)
        annotations.update(extra_annotations)
    else:
        raise ValueError(f"Unknown k8s.type: {k8s_type}")

    if k8s_type.startswith("service"):
        annotations["warning"] = "service-account-token is usually not static; consider TokenRequest/workload identity"

    fields = list(data.keys())
    if k8s_output == "k8s":
        return build_k8s_secret(k8s_name, namespace, secret_type, labels, annotations, data, fields)
    if k8s_output == "openbao":
        return build_external_secret(k8s_name, namespace, k8s_name, secret_type, labels, annotations, remote_key_rel, fields, k8s_sync)
    raise ValueError(f"Unknown k8s.output: {k8s_output}")


def write_yaml(path: Path, documents: List[Dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        yaml.dump_all(documents, handle)

def build_namespace_manifest(namespace: str) -> List[Dict[str, Any]]:
    return [
        {
            "apiVersion": "v1",
            "kind": "Namespace",
            "metadata": {
                "name": namespace,
                "labels": {
                    "kubernetes.io/metadata.name": namespace,
                    "app.kubernetes.io/name": namespace,
                },
            },
            "spec": {"finalizers": ["kubernetes"]},
        },
        {
            "apiVersion": "v1",
            "kind": "ServiceAccount",
            "metadata": {
                "name": f"{namespace}-sa",
                "namespace": namespace,
                "labels": {"app.kubernetes.io/managed-by": "keepass-to-eso-openbao-py"},
                "annotations": {"openbao.mount": namespace},
            },
        },
        {
            "apiVersion": "rbac.authorization.k8s.io/v1",
            "kind": "Role",
            "metadata": {
                "name": f"{namespace}-writer",
                "namespace": namespace,
                "labels": {
                    "security": "cis",
                    "app.kubernetes.io/managed-by": "keepass-to-eso-openbao-py",
                },
                "annotations": {"openbao.mount": namespace},
            },
            "rules": [
                {"apiGroups": [""], "resources": ["pods"], "verbs": ["get"]},
                {"apiGroups": ["secrets-store.csi.x-k8s.io"], "resources": ["secretproviderclasses"], "verbs": ["get", "list", "watch"]},
                {"apiGroups": ["secrets-store.csi.x-k8s.io"], "resources": ["secretproviderclasspodstatuses"], "verbs": ["create", "get", "update", "patch"]},
                {"apiGroups": [""], "resources": ["events"], "verbs": ["create", "patch"]},
                {"apiGroups": [""], "resources": ["secrets"], "verbs": ["create", "update", "patch", "delete"]},
            ],
        },
        {
            "apiVersion": "rbac.authorization.k8s.io/v1",
            "kind": "RoleBinding",
            "metadata": {
                "name": f"{namespace}-swb",
                "namespace": namespace,
                "labels": {"app.kubernetes.io/managed-by": "keepass-to-eso-openbao-py"},
                "annotations": {"openbao.mount": namespace},
            },
            "roleRef": {
                "kind": "Role",
                "name": f"{namespace}-writer",
                "apiGroup": "rbac.authorization.k8s.io",
            },
            "subjects": [{"kind": "ServiceAccount", "name": f"{namespace}-sa", "namespace": namespace}],
        },
    ]


def build_openbao_upload_script(namespace: str, curr_time: str) -> List[str]:
    lines = [
        "#!/usr/bin/env bash",
        "set -euo pipefail",
        "",
        'openbaospace="openbao"',
        'kubectl="sudo microk8s kubectl"',
        "",
        'if [ -z "${OPENBAO_ROOT_TOKEN:-}" ]; then',
        '  echo "Error: OPENBAO_ROOT_TOKEN must be set" >&2',
        '  exit 1',
        'fi',
        "",
        'if ! ${kubectl} -n "${openbaospace}" get pod openbao-0 >/dev/null 2>&1; then',
        '  echo "Error: OpenBao pod openbao-0 not found in namespace ${openbaospace}" >&2',
        '  exit 1',
        'fi',
        "",
        '# Login',
        'roottoken="${OPENBAO_ROOT_TOKEN}"',
        'echo "${roottoken}" | ${kubectl} --namespace="${openbaospace}" exec -i openbao-0 -- bao login -',
        "",
        f'echo "Creating policy for secretspace {namespace}..."',
        f'cat <<EOF | ${{kubectl}} --namespace="${{openbaospace}}" exec -i openbao-0 -- bao policy write {namespace} -',
        '# SPDX-License-Identifier: MPL-2.0',
        '# Source and License see: https://github.com/Alfred-Sabitzer/microk8s-ubuntu/tree/main/applications/keepassxc',
        f'# Created on {curr_time}',
        f'path "secret/data/{namespace}/*" {{',
        '  capabilities = ["read"]',
        '}',
        'EOF',
        "",
        f'echo "Configuring role for secretspace {namespace}..."',
        f'${{kubectl}} --namespace=${{openbaospace}} exec openbao-0 -- bao write auth/kubernetes/role/{namespace}-role \\',
        f'    bound_service_account_names={namespace}-sa \\',
        f'    bound_service_account_namespaces={namespace} \\',
        '    audience="https://kubernetes.default.svc" \\',
        f'    policies={namespace} \\',
        '    ttl=20m',
        "",
        f'echo "Activating secrets engine and creating secret for secretspace {namespace}"',
        f'${{kubectl}} --namespace=${{openbaospace}} exec -i openbao-0 -- bao kv delete -mount=secret {namespace} || true',
        f'echo "Create secret for secretspace {namespace}"',
    ]
    return lines


def main() -> None:
    ap = argparse.ArgumentParser(description="KeePassXC -> Kubernetes manifests / OpenBao export")
    ap.add_argument("--kdbx", required=True, help="Path to the .kdbx database")
    ap.add_argument("--password", help="Database password (or env KEEPASS_PASSWORD)")
    ap.add_argument("--keyfile", help="Optional keyfile path")
    ap.add_argument("--outdir", default="out", help="Output directory")
    ap.add_argument("--mount", default="kv", help="Default OpenBao mount")
    ap.add_argument("--prefix", default="k8s", help="Default prefix for generated OpenBao paths")

    args = ap.parse_args()

    password = args.password or os.environ.get("KEEPASS_PASSWORD")
    if not password:
        raise SystemExit("Provide --password or set KEEPASS_PASSWORD")

    output_dir = Path(args.outdir)
    if output_dir.exists():
        remove_directory_tree(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / ".gitignore").write_text("*\n", encoding="utf-8")

    kp = PyKeePass(args.kdbx, password=password, keyfile=args.keyfile)

    external_secrets: List[Dict[str, Any]] = []
    errors: List[str] = []
    seen_names: set[Tuple[str, str]] = set()

    for entry in kp.entries:
        if getattr(entry, "is_in_recycle_bin", False):
            continue
        if not (entry.title or "").strip():
            continue
        try:
            manifest = entry_to_outputs(entry, args.mount, args.kdbx)
            namespace = manifest["metadata"]["namespace"]
            name = manifest["metadata"]["name"]
            key = (namespace, name)
            if key in seen_names:
                errors.append(f"Name collision: manifest {namespace}/{name} derived from multiple entries")
                continue
            seen_names.add(key)
            external_secrets.append(manifest)
        except Exception as exc:  # pragma: no cover - runtime validation path
            group_name = "/".join(group_path_parts(entry.group))
            errors.append(f"{group_name} :: {entry.title}: {exc}")

    for manifest in external_secrets:
        namespace = manifest["metadata"]["namespace"]
        name = manifest["metadata"]["name"]
        manifest_dir = output_dir / namespace
        manifest_dir.mkdir(parents=True, exist_ok=True)
        write_yaml(manifest_dir / f"{name}.yaml", [manifest])

    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    seen_namespaces: set[str] = set()
    namespace_shells: Dict[str, List[str]] = {}

    for manifest in external_secrets:
        namespace = manifest["metadata"]["namespace"]
        if namespace in seen_namespaces:
            continue
        seen_namespaces.add(namespace)
        namespace_shells[namespace] = build_openbao_upload_script(namespace, now)
        write_yaml(output_dir / f"{namespace}.yaml", build_namespace_manifest(namespace))

    for entry in kp.entries:
        if getattr(entry, "is_in_recycle_bin", False):
            continue
        if not (entry.title or "").strip():
            continue
        props = get_custom_properties(entry)
        parts = group_path_parts(entry.group)
        k8s_output = (props.get("k8s.output") or "k8s").strip().lower()
        if k8s_output != "openbao":
            continue

        namespace = props.get("k8s.ns") or namespace_from_folder(parts)
        k8s_name_raw = props.get("k8s.name") or entry.title or "secret"
        k8s_name = slug_dns1123(k8s_name_raw)
        k8s_type = (props.get("k8s.type") or "opaque").strip().lower()

        if k8s_type == "opaque":
            _, data = build_opaque(entry, props)
        elif k8s_type == "tls":
            _, data = build_tls(entry, props)
        elif k8s_type in ("dockerconfigjson", "docker", "registry"):
            _, data = build_dockerconfigjson(entry, props)
        elif k8s_type == "ssh":
            _, data = build_ssh(entry, props)
        elif k8s_type in ("basicauth", "basic-auth"):
            _, data = build_basic_auth(entry, props)
        elif k8s_type in ("serviceaccounttoken", "service-account-token", "satoken"):
            _, data, _ = build_serviceaccount_token(entry, props)
        else:
            raise ValueError(f"Unknown k8s.type: {k8s_type}")

        secret_parts = []
        for field_name, field_value in data.items():
            encoded = b64(field_value)
            secret_parts.append(f'{field_name}="$(echo \'{encoded}\' | base64 --decode)"')

        namespace_shells.setdefault(namespace, []).extend([
            f'${{kubectl}} --namespace="${{openbaospace}}" exec -i openbao-0 -- bao kv delete secret/{namespace}/{k8s_name} || true',
            f'${{kubectl}} --namespace="${{openbaospace}}" exec -i openbao-0 -- bao kv put secret/{namespace}/{k8s_name}  ' + " ".join(secret_parts),
        ])

    for namespace, lines in namespace_shells.items():
        script_path = output_dir / f"{namespace}.sh"
        script_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
        script_path.chmod(0o755)

    errors_path = output_dir / "errors.txt"
    if errors:
        errors_path.write_text("\n".join(errors) + "\n", encoding="utf-8")
    else:
        errors_path.unlink(missing_ok=True)

    print(f"Wrote {len(external_secrets)} manifests to {output_dir}/")
    if errors:
        print(f"Wrote {len(errors)} errors to {errors_path}")


if __name__ == "__main__":
    main()
