#!/bin/bash
############################################################################################
#
# Create some stress for CephFS in MicroCeph.
# See https://starbeamrainbowlabs.com/blog/article.php?article=posts%2F290-Disk-Performance-Mesuring.html
# Usage:
#   sudo ./cephfs_test.sh
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
shopt -o -s xtrace #—Displays each command before it is executed.
shopt -o -s nounset #-No Variables without definition
set -euo pipefail

# Create a test file of 1 GiB
dd if=/dev/zero of=/tmp/testfile.bin bs=1M count=1024

# Use the sync command. sync will flush all cached write operations to disk for us, giving us the actual time it took to write the 1 GiB file to disk. Here's the altered command:
echo "Write Test:"
sync;
time sh -c 'dd if=/tmp/testfile.bin >/data/testfile.bin; sync'

# Well, to test that, we'll first need to clear out the page cache - another one of Linux's (many) caches that holds portions of files that have recently been accessed for faster retrieval - because as before, we're not interested in the speed of the cache! Here's how to do that:
echo "Read Test:"
# This is not working in LXD-Containers
# see https://discuss.linuxcontainers.org/t/drop-caches-permission-denied/14176
#echo 1 | sudo tee /proc/sys/vm/drop_caches
time dd if=/data/testfile.bin of=/dev/null

# Clean up
rm /tmp/testfile.bin
rm /data/testfile.bin
echo "Test file removed."
# Note: For more accurate results, consider repeating the tests multiple times and averaging the results.
echo "CephFS stress test completed."

