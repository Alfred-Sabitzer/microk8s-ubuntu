import os
import subprocess
import unittest
from pathlib import Path
from unittest.mock import patch

import backup


def sample_config() -> backup.Config:
    return backup.Config(
        bucket="test-velero",
        s3_endpoint="http://127.0.0.1:8081",
        s3_region="default",
        s3_access_key="access",
        s3_secret_key="secret",
        gpg_passphrase="passphrase",
        ssh_host="backup.example.test",
        ssh_user="backup",
        ssh_remote_path="/backups",
        ssh_port=22,
        ssh_key_file=Path("/run/ssh/id_ed25519"),
        ssh_known_hosts_file=Path("/run/ssh/known_hosts"),
        source_mount=Path("/mnt/source"),
        destination_mount=Path("/mnt/remote"),
        destination_path=Path("/mnt/remote/duplicity/test-velero"),
        archive_dir=Path("/tmp/duplicity-cache"),
    )


class ConfigTests(unittest.TestCase):
    def test_rejects_non_http_endpoint(self) -> None:
        environment = {
            "S3_ENDPOINT": "ftp://storage.example.test",
            "S3_REGION": "default",
            "S3_ACCESS_KEY": "access",
            "S3_SECRET_KEY": "secret",
            "GPG_PASSPHRASE": "passphrase",
            "SSH_HOST": "backup.example.test",
            "SSH_USER": "backup",
            "SSH_REMOTE_PATH": "/backups",
        }
        with patch.dict(os.environ, environment, clear=True):
            with self.assertRaisesRegex(backup.BackupError, "S3_ENDPOINT"):
                backup.Config.from_environment()

    def test_rejects_s3_password_file_delimiters(self) -> None:
        environment = {
            "S3_ENDPOINT": "http://storage.example.test",
            "S3_REGION": "default",
            "S3_ACCESS_KEY": "access:extra",
            "S3_SECRET_KEY": "secret",
            "GPG_PASSPHRASE": "passphrase",
            "SSH_HOST": "backup.example.test",
            "SSH_USER": "backup",
            "SSH_REMOTE_PATH": "/backups",
        }
        with patch.dict(os.environ, environment, clear=True):
            with self.assertRaisesRegex(backup.BackupError, "S3_ACCESS_KEY"):
                backup.Config.from_environment()


class DuplicityTests(unittest.TestCase):
    @patch("backup.subprocess.run")
    def test_prunes_only_after_backup_succeeds(
        self, run_process: unittest.mock.MagicMock
    ) -> None:
        with patch("backup.Path.mkdir"):
            backup._run_duplicity(sample_config())

        self.assertEqual(run_process.call_count, 2)
        backup_command = run_process.call_args_list[0].args[0]
        retention_command = run_process.call_args_list[1].args[0]
        self.assertIn("--full-if-older-than", backup_command)
        self.assertNotIn("--no-encryption", backup_command)
        self.assertEqual(retention_command[1:4], ["remove-older-than", "2W", "--force"])
        self.assertEqual(run_process.call_args_list[0].kwargs["env"]["PASSPHRASE"], "passphrase")

    @patch("backup.subprocess.run", side_effect=subprocess.CalledProcessError(1, "duplicity"))
    def test_does_not_prune_after_backup_failure(
        self, run_process: unittest.mock.MagicMock
    ) -> None:
        with patch("backup.Path.mkdir"):
            with self.assertRaises(subprocess.CalledProcessError):
                backup._run_duplicity(sample_config())
        self.assertEqual(run_process.call_count, 1)


if __name__ == "__main__":
    unittest.main()
