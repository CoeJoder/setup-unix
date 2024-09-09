#!/bin/bash
set -Eeuo pipefail	# bash strict-mode
read -p "Target disk (e.g. /dev/xyz): " DISK
if [[ -z $DISK ]]; then
	echo "No disk specified"
	exit 1
fi
PHYSICALSIZE=$(sudo blockdev --getsize64 $DISK)
BLOCKSIZE=$(sudo blockdev --getbsz $DISK)
if [[ ! $PHYSICALSIZE =~ ^[0-9]+$ ]]; then
	echo "Invalid physical size: ${PHYSICALSIZE:-empty}"
	exit 1
fi
if [[ ! $BLOCKSIZE =~ ^[0-9]+$ ]]; then
	echo "Invalid block size: ${BLOCKSIZE:-empty}"
	exit 1
fi
NUMSECTORS=$(($PHYSICALSIZE / $BLOCKSIZE))
echo "Physical size of $DISK detected as $PHYSICALSIZE B"
echo "Block size of $DISK detected as $BLOCKSIZE B"
echo "Number of sectors on $DISK detected as $NUMSECTORS"
read -p "Continue with secure wipe? (y/N): " confirm && \
    [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
sudo dd if=/dev/urandom iflag=fullblock of=$DISK bs=$BLOCKSIZE count=$NUMSECTORS seek=0 status=progress
