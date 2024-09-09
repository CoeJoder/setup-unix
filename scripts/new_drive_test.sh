#!/bin/bash
set -Eeuo pipefail	# bash strict-mode
read -p "Target disk (e.g. /dev/xyz): " DISK
if [[ -z $DISK ]]; then
	echo "No disk specified"
	exit 1
fi
BLOCKSIZE=$(sudo blockdev --getbsz $DISK)
if [[ ! $BLOCKSIZE =~ ^[0-9]+$ ]]; then
	echo "Invalid block size: ${BLOCKSIZE:-empty}"
	exit 1
fi
echo "Block size of $DISK detected as $BLOCKSIZE B"
read -p "Continue with destructive r/w test? (y/N): " confirm && \
    [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
sudo badblocks -wsvb $BLOCKSIZE $DISK
