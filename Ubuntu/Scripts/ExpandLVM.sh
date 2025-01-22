#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

echo "Checking current filesystem and LVM setup..."

# Get the root logical volume, volume group, and filesystem details
ROOT_LV=$(df / | tail -1 | awk '{print $1}')
VG_NAME=$(lvs --noheadings -o vg_name "$ROOT_LV" | xargs)
LV_NAME=$(lvs --noheadings -o lv_name "$ROOT_LV" | xargs)

if [ -z "$ROOT_LV" ] || [ -z "$VG_NAME" ] || [ -z "$LV_NAME" ]; then
  echo "Error: Unable to detect root logical volume. Ensure the system is using LVM."
  exit 1
fi

echo "Detected root volume: $ROOT_LV"
echo "Volume group: $VG_NAME"
echo "Logical volume: $LV_NAME"

# Display free space in the volume group
FREE_SPACE=$(vgs --noheadings -o vg_free "$VG_NAME" | xargs)
if [ "$FREE_SPACE" == "0" ]; then
  echo "No free space available in the volume group $VG_NAME. Exiting."
  exit 1
fi

echo "Free space in volume group $VG_NAME: $FREE_SPACE"

echo "Expanding logical volume for / to use 100% of the available space..."
# Expand the logical volume
lvextend -l +100%FREE "/dev/$VG_NAME/$LV_NAME"

# Resize the filesystem
echo "Resizing the filesystem on / to utilize the expanded space..."
resize2fs "/dev/$VG_NAME/$LV_NAME"

# Verify the new size
echo "Updated root filesystem size:"
df -h /

echo "Expansion of / is complete."