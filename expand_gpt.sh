#!/bin/bash

# script to expand gpt disk image to 15GB

set -xe

if [ -z "$1" ]; then
  echo "Usage: $0 <image-file>"
  exit 1
fi

# if ends with xz, uncompress first
if [[ "$1" == *.xz ]]; then
  unxz --keep -T0 "$1"
  IMAGE="${1%.xz}"
else
  IMAGE="$1"
fi


# expand the image to 15GB
truncate -s 15GB "$IMAGE"
# get the last partition number
PART_NUM=$(parted -s "$IMAGE" print | awk '/^ / {print $1}' | tail -n1)
# get the start of the last partition
PART_START=$(parted -s "$IMAGE" print | awk -v num="$PART_NUM" '$1 == num {print $2}' | sed 's/[^0-9]//g')
# get the end of the last partition
PART_END=$(parted -s "$IMAGE" print | awk -v num="$PART_NUM" '$1 == num {print $3}' | sed 's/[^0-9]//g')
# get the type of the last partition
PART_TYPE=$(parted -s "$IMAGE" print | awk -v num="$PART_NUM" '$1 == num {print $5}')
# get the file system type of the last partition
PART_FS=$(parted -s "$IMAGE" print | awk -v num="$PART_NUM" '$1 == num {print $6}')


# use parted to resize the last partition to the end of the disk
echo -e "fix\nresizepart\nFix\n2\n100%\nYes" | sudo parted ---pretend-input-tty "$IMAGE"
IMAGE_NEW_NAME="${IMAGE%.img}_expanded.img"
mv "$IMAGE" "$IMAGE_NEW_NAME"
IMAGE="$IMAGE_NEW_NAME"
xz -T0 -k "$IMAGE"