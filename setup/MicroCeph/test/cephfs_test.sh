#!/usr/bin/env bash
############################################################################################
#
# CephFS basic throughput test (write + read)
# - Creates a temporary file, writes it to target mount (/data by default)
# - Attempts to drop caches (if running as root and supported)
# - Measures wall-clock time for write and read
#
# Usage:
#   sudo ./cephfs_test.sh            # default: /data, 1024 MiB
#   sudo FILE_SIZE_MB=512 TARGET=/mnt/ceph ./cephfs_test.sh
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it's executed.
shopt -o -s nounset #-No Variables without definition
set -euo pipefail
trap 'rc=$?; cleanup; exit $rc' EXIT

# Configurable via env:
FILE_SIZE_MB="${FILE_SIZE_MB:-1024}"   # MiB
TARGET="${TARGET:-/mnt/rook}"
TMPDIR="${TMPDIR:-/tmp}"
TMPFILE="$(mktemp "${TMPDIR}/cephfs-test.XXXXXX.bin")"
DEST_FILE="${DEST_FILE:-${TARGET}/cephfs-test.bin}"
DD_OPTS="${DD_OPTS:-bs=1M}"
USE_DIRECT="${USE_DIRECT:-1}"  # try oflag=direct if supported
TIME_CMD="${TIME_CMD:-/usr/bin/time -p}"

cleanup() {
  set +e
  [ -f "${TMPFILE}" ] && rm -f "${TMPFILE}"
  # Do not remove DEST_FILE automatically unless KEEP_DEST not set to true
  if [ "${KEEP_DEST:-false}" != "true" ] && [ -f "${DEST_FILE}" ]; then
    rm -f "${DEST_FILE}" || true
  fi
}

die(){ echo "ERROR: $*" >&2; exit 2; }

# Prereqs
if ! command -v dd >/dev/null 2>&1; then
  die "dd not found in PATH"
fi

if [ ! -d "${TARGET}" ]; then
  die "Target directory '${TARGET}' does not exist. Create/mount it before running."
fi

if [ ! -w "${TARGET}" ]; then
  die "No write permission to target '${TARGET}'. Run as user that can write or use sudo."
fi

if [ "$(id -u)" -ne 0 ]; then
  echo "Warning: running as non-root. Cache drop and direct I/O may not work. Consider running with sudo."
fi

#
# Ensure time command is available
#
apt-get update
apt-get install time
if ! command -v ${TIME_CMD%% *} >/dev/null 2>&1; then
  die "time command not found in PATH: ${TIME_CMD}"
fi
# create local tmp file
echo "Creating local temp file (${FILE_SIZE_MB} MiB) at ${TMPFILE} ..."
dd if=/dev/zero of="${TMPFILE}" ${DD_OPTS} count="${FILE_SIZE_MB}" status=none
echo "Temp file created: ${TMPFILE} (${FILE_SIZE_MB} MiB)"

# Write test
echo "Write test -> ${DEST_FILE}"
WRITE_CMD=(dd if="${TMPFILE}" of="${DEST_FILE}" ${DD_OPTS} count="${FILE_SIZE_MB}")
# try to add direct I/O if requested and supported
if [ "${USE_DIRECT}" = "1" ]; then
  if dd of=/dev/null oflag=direct >/dev/null 2>&1 </dev/null; then
    WRITE_CMD+=("oflag=direct")
  fi
fi

echo "Running write (syncing after write) ..."
{ time_out=$($TIME_CMD "${WRITE_CMD[@]}" 2>&1) ; } || true
# make sure data is flushed
sync || true
echo "Write finished."
echo "${time_out}"

# Attempt to drop caches (only works as root, may be disabled in containers)
if [ "$(id -u)" -eq 0 ]; then
  if [ -w /proc/sys/vm/drop_caches ]; then
    echo "Dropping page cache (echo 3 > /proc/sys/vm/drop_caches) ..."
    echo 3 > /proc/sys/vm/drop_caches || echo "Warning: failed to drop caches"
  else
    echo "Warning: cannot write /proc/sys/vm/drop_caches (permission or not supported in container)"
  fi
else
  echo "Non-root: skipping drop_caches. Read test may be served from cache."
fi

# Read test
echo "Read test (from ${DEST_FILE}) ..."
if [ ! -f "${DEST_FILE}" ]; then
  die "Destination file not found: ${DEST_FILE}"
fi

# read with direct if possible
READ_CMD=(dd if="${DEST_FILE}" of=/dev/null ${DD_OPTS} count="${FILE_SIZE_MB}")
if [ "${USE_DIRECT}" = "1" ]; then
  if dd of=/dev/null oflag=direct >/dev/null 2>&1 </dev/null; then
    READ_CMD+=("iflag=direct")
  fi
fi

{ time_out=$($TIME_CMD "${READ_CMD[@]}" 2>&1) ; } || true
echo "Read finished."
echo "${time_out}"

# Cleanup handled by trap unless KEEP_DEST=true
echo "Test completed. Temp file removed; destination file ${DEST_FILE} ${KEEP_DEST:-was removed}."

exit 0

