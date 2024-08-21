#!/bin/bash
IMAGE_LOCATION=$1 # Image file location [e.g. /home/user/image.img]
DEVICE=$2 ##Device. Ex: "/dev/sdb" USB drive, "/dev/mmcblk0" SD card

BOOTPARTITION="${DEVICE}p1"
ROOTPARTITION_1="${DEVICE}p2"
ROOTPARTITION_2="${DEVICE}p3"

NEWCMDLINE=""
PARTITION1_CMDLINE="/tmp/partition1cmd.txt"
PARTITION2_CMDLINE="/tmp/partition2cmd.txt"

NEWFSTAB=""
PARTITION1_FSTAB="/tmp/partition1fstab.txt"
PARTITION2_FSTAB="/tmp/partition2fstab.txt"

ACTIVE_PARTITION=$(mount | grep 'on / type' | awk '{print $1}')


install_dependencies() {
    sudo apt-get update >&1
    sudo apt-get install kpartx >&1
}

cleanup() {
    sudo umount /mnt/boot >&1
    sudo umount /mnt/target_root >&1
    sudo umount /mnt/mapped_root >&1
    sudo umount /mnt/mapped_boot >&1
    sudo kpartx -dv $IMAGE_LOCATION >&1`    `
}


# Error handling function
exit_cleanup() {
    # Add any cleanup commands here
    echo "An error has occured." >&1
    cleanup
    exit 1
}

echo "Starting firmware transfer." >&1

install_dependencies

inactive_partition=""

if [ "$ACTIVE_PARTITION" == "$ROOTPARTITION_1" ]; then
    inactive_partition=$ROOTPARTITION_2
    NEWCMDLINE=$PARTITION2_CMDLINE
    NEWFSTAB=$PARTITION2_FSTAB
else
    inactive_partition=$ROOTPARTITION_1
    NEWCMDLINE=$PARTITION1_CMDLINE
    NEWFSTAB=$PARTITION1_FSTAB
fi
echo "inactive partition: $inactive_partition" >&1
echo "new cmdline: $NEWCMDLINE" >&1
echo "new fstab: $NEWFSTAB" >&1

# Set trap to catch errors and call cleanup_and_exit
trap exit_cleanup ERR

#map partitions in image
sudo kpartx -asv $IMAGE_LOCATION >&1

sudo mkdir -p /mnt/mapped_root >&1
sudo mkdir -p /mnt/mapped_boot >&1
sudo mkdir -p /mnt/boot >&1
sudo mkdir -p /mnt/target_root >&1

#img files will create two mapped dirs: the boot (loop0p1) and the root (loop0p2).
sudo mount /dev/mapper/loop0p1 /mnt/mapped_boot >&1
sudo mount /dev/mapper/loop0p2 /mnt/mapped_root >&1

sudo mkfs.ext4 $inactive_partition  # format partition, just in case

sudo mount $inactive_partition /mnt/target_root >&1
sudo mount $BOOTPARTITION /mnt/boot

sudo rsync -aAXv --iconv=UTF-8,UTF-8 /mnt/mapped_root/ /mnt/target_root/
echo "copied root fs over" >&1
sudo rsync -aAXv /mnt/mapped_boot/ /mnt/boot/ 

#transfer new bootline and fstab partition mapping
sudo cp "$NEWCMDLINE" "/mnt/boot/cmdline.txt" >&1
sudo cp "$NEWFSTAB" "/mnt/target_root/etc/fstab" >&1

# Clean up
cleanup

echo "rebooting to the new firmware..." >&1
sudo reboot -f >&1

exit 0