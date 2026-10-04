#!/usr/bin/env python3
"""Back up an S3-compatible bucket to an SSHFS-mounted Duplicity destination."""

from __future__ import annotations

import logging
import os
import signal
import subprocess
import sys
import tempfile
import time
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import urlsplit

LOG = logging.getLogger("duplicity-backup")
MOUNT_TIMEOUT_SECONDS = 60
MOUNT_POLL_INTERVAL_SECONDS = 1


class BackupError(RuntimeError):
    """Raised when configuration, mounting, backup, or retention fails."""


@dataclass(frozen=True)
class Config:
    bucket: str
    s3_endpoint: str
    s3_region: str
    s3_access_key: str
    s3_secret_key: str
    gpg_passphrase: str
    ssh_host: str
    ssh_user: str
    ssh_remote_path: str
    ssh_port: int
    ssh_key_file: Path
    ssh_known_hosts_file: Path
    source_mount: Path
    destination_mount: Path
    destination_path: Path
    archive_dir: Path

    @classmethod
    def from_environment(cls) -> Config:
        required = (
            "S3_ENDPOINT",
            "S3_REGION",
            "S3_ACCESS_KEY",
            "S3_SECRET_KEY",
            "GPG_PASSPHRASE",
            "SSH_HOST",
            "SSH_USER",
            "SSH_REMOTE_PATH",
        )
        missing = [name for name in required if not os.environ.get(name)]
        if missing:
            raise BackupError(f"Missing required environment variables: {', '.join(missing)}")

        endpoint = os.environ["S3_ENDPOINT"]
        parsed_endpoint = urlsplit(endpoint)
        if parsed_endpoint.scheme not in ("http", "https") or not parsed_endpoint.netloc:
            raise BackupError("S3_ENDPOINT must be an http:// or https:// URL")

        try:
            ssh_port = int(os.environ.get("SSH_PORT", "22"))
        except ValueError as error:
            raise BackupError("SSH_PORT must be an integer between 1 and 65535") from error
        if not 1 <= ssh_port <= 65535:
            raise BackupError("SSH_PORT must be an integer between 1 and 65535")

        access_key = os.environ["S3_ACCESS_KEY"]
        secret_key = os.environ["S3_SECRET_KEY"]
        for label, credential in (("S3_ACCESS_KEY", access_key), ("S3_SECRET_KEY", secret_key)):
            if any(character in credential for character in (":", "\n", "\r")):
                raise BackupError(f"{label} contains a character unsupported by s3fs password files")

        return cls(
            bucket=os.environ.get("S3_BUCKET", "test-velero"),
            s3_endpoint=endpoint,
            s3_region=os.environ["S3_REGION"],
            s3_access_key=access_key,
            s3_secret_key=secret_key,
            gpg_passphrase=os.environ["GPG_PASSPHRASE"],
            ssh_host=os.environ["SSH_HOST"],
            ssh_user=os.environ["SSH_USER"],
            ssh_remote_path=os.environ["SSH_REMOTE_PATH"],
            ssh_port=ssh_port,
            ssh_key_file=Path(os.environ.get("SSH_KEY_FILE", "/run/ssh/id_ed25519")),
            ssh_known_hosts_file=Path(
                os.environ.get("SSH_KNOWN_HOSTS_FILE", "/run/ssh/known_hosts")
            ),
            source_mount=Path(os.environ.get("SOURCE_MOUNT", "/mnt/source")),
            destination_mount=Path(os.environ.get("DESTINATION_MOUNT", "/mnt/remote")),
            destination_path=Path(
                os.environ.get(
                    "DESTINATION_PATH",
                    "/mnt/remote/duplicity/test-velero",
                )
            ),
            archive_dir=Path(os.environ.get("DUPLICITY_ARCHIVE_DIR", "/tmp/duplicity-cache")),
        )


def _mount_is_ready(path: Path) -> bool:
    result = subprocess.run(
        ["mountpoint", "-q", str(path)],
        check=False,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    return result.returncode == 0


def _start_mount(command: list[str], path: Path) -> subprocess.Popen[bytes]:
    path.mkdir(parents=True, exist_ok=True)
    if _mount_is_ready(path):
        raise BackupError(f"Refusing to use an already-mounted path: {path}")

    LOG.info("Mounting %s", path)
    process = subprocess.Popen(command)
    try:
        deadline = time.monotonic() + MOUNT_TIMEOUT_SECONDS
        while time.monotonic() < deadline:
            if process.poll() is not None:
                raise BackupError(f"Mount command exited with status {process.returncode}: {path}")
            if _mount_is_ready(path):
                return process
            time.sleep(MOUNT_POLL_INTERVAL_SECONDS)

        raise BackupError(f"Timed out waiting for mount: {path}")
    except BaseException:
        _stop_process(process)
        raise


def _unmount(path: Path) -> None:
    if not _mount_is_ready(path):
        return

    last_error: subprocess.CalledProcessError | None = None
    for command in (["fusermount3", "-u", str(path)], ["fusermount", "-u", str(path)]):
        try:
            subprocess.run(command, check=True)
            LOG.info("Unmounted %s", path)
            return
        except FileNotFoundError:
            continue
        except subprocess.CalledProcessError as error:
            last_error = error

    if last_error is not None:
        raise BackupError(f"Could not unmount {path}: {last_error}") from last_error
    raise BackupError("Neither fusermount3 nor fusermount is installed")


def _stop_process(process: subprocess.Popen[bytes]) -> None:
    if process.poll() is None:
        process.terminate()
        try:
            process.wait(timeout=10)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()


def _run_duplicity(config: Config) -> None:
    config.destination_path.mkdir(parents=True, exist_ok=True)
    config.archive_dir.mkdir(parents=True, exist_ok=True)
    destination_url = config.destination_path.as_uri()
    environment = os.environ.copy()
    environment["PASSPHRASE"] = config.gpg_passphrase

    backup_command = [
        "duplicity",
        "--archive-dir",
        str(config.archive_dir),
        "--full-if-older-than",
        os.environ.get("DUPLICITY_FULL_IF_OLDER_THAN", "1W"),
        str(config.source_mount),
        destination_url,
    ]
    LOG.info("Starting encrypted backup of bucket %s", config.bucket)
    subprocess.run(backup_command, check=True, env=environment)

    retention_command = [
        "duplicity",
        "remove-older-than",
        os.environ.get("DUPLICITY_RETENTION", "2W"),
        "--force",
        "--archive-dir",
        str(config.archive_dir),
        destination_url,
    ]
    LOG.info("Pruning backup history older than %s", os.environ.get("DUPLICITY_RETENTION", "2W"))
    subprocess.run(retention_command, check=True, env=environment)


def run(config: Config) -> None:
    if not config.ssh_key_file.is_file():
        raise BackupError(f"SSH private key file does not exist: {config.ssh_key_file}")
    if not config.ssh_known_hosts_file.is_file():
        raise BackupError(f"SSH known_hosts file does not exist: {config.ssh_known_hosts_file}")

    mount_processes: list[tuple[subprocess.Popen[bytes], Path]] = []
    credential_file: str | None = None
    primary_error: BaseException | None = None
    try:
        file_descriptor, credential_file = tempfile.mkstemp(prefix="s3fs-", dir="/tmp")
        with os.fdopen(file_descriptor, "w", encoding="utf-8") as credentials:
            os.fchmod(credentials.fileno(), 0o600)
            credentials.write(f"{config.s3_access_key}:{config.s3_secret_key}\n")

        s3fs_command = [
            "s3fs",
            config.bucket,
            str(config.source_mount),
            "-f",
            "-o",
            f"passwd_file={credential_file}",
            "-o",
            f"url={config.s3_endpoint}",
            "-o",
            f"endpoint={config.s3_region}",
            "-o",
            "use_path_request_style",
        ]
        mount_processes.append(
            (_start_mount(s3fs_command, config.source_mount), config.source_mount)
        )

        remote = f"{config.ssh_user}@{config.ssh_host}:{config.ssh_remote_path}"
        sshfs_command = [
            "sshfs",
            "-f",
            "-p",
            str(config.ssh_port),
            "-o",
            f"IdentityFile={config.ssh_key_file}",
            "-o",
            f"UserKnownHostsFile={config.ssh_known_hosts_file}",
            "-o",
            "StrictHostKeyChecking=yes",
            "-o",
            "BatchMode=yes",
            "-o",
            "reconnect",
            remote,
            str(config.destination_mount),
        ]
        mount_processes.append(
            (_start_mount(sshfs_command, config.destination_mount), config.destination_mount)
        )
        _run_duplicity(config)
    except BaseException as error:
        primary_error = error
        raise
    finally:
        cleanup_errors: list[BackupError] = []
        for process, path in reversed(mount_processes):
            try:
                _unmount(path)
            except BackupError as error:
                cleanup_errors.append(error)
                LOG.error("%s", error)
            finally:
                _stop_process(process)
        if credential_file is not None:
            Path(credential_file).unlink(missing_ok=True)
        if cleanup_errors and primary_error is None:
            raise cleanup_errors[0]


def main() -> int:
    logging.basicConfig(
        level=os.environ.get("LOG_LEVEL", "INFO").upper(),
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    )

    def handle_termination(signum: int, _frame: object) -> None:
        del _frame
        raise SystemExit(128 + signum)

    signal.signal(signal.SIGTERM, handle_termination)
    signal.signal(signal.SIGINT, handle_termination)
    try:
        run(Config.from_environment())
    except (BackupError, subprocess.CalledProcessError) as error:
        LOG.error("Backup failed: %s", error)
        return 1
    except FileNotFoundError as error:
        LOG.error("Required executable or file is missing: %s", error)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
