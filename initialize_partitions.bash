IMAGE=$1 # Image file location
DEVICE=$2 #Device. Ex: "/dev/sdb" USB drive, "/dev/mmcblk0" SD card
DISK_SIZE=$3 #Disk size in GB.

if [ -z "$IMAGE" ]; then
    echo "No image file specified. Exiting."
    exit 1
elif [ -z "$DEVICE" ]; then
    echo "No device specified. Exiting."
    exit 1
elif [ -z "$DISK_SIZE" ]; then
    echo "No disk size specified. Exiting."
    exit 1
fi

#Partition size = Full Disk - (512M [for boot]) / 2
PARTITION_SIZE=$(echo "($DISK_SIZE - 0.5) / 2" | bc)G

# Unmount all partitions (just in case)
sudo umount ${DEVICE}1
sudo umount ${DEVICE}2
sudo umount ${DEVICE}3

#clear device + partitions
sudo dd if='/dev/zero' of=$DEVICE bs=4M conv=fsync status=progress

#we dd' the os onto the blank device, creating two partitions (boot {DEVICE1}
#and root {DEVICE2} ). root is minimum size, but we want to initialize it to 
#PARTITION_SIZE because it won't be able to expand later due to the second root partition

#flash device
sudo dd if=$IMAGE of=$DEVICE bs=4M conv=fsync status=progress

#get start of root partition
R1_START=$(sudo fdisk -l $DEVICE | grep "^${DEVICE}2" | awk '{print $2}')


#Delete root partition, recreate w/ larger size of PARTITION_SIZE
sudo fdisk $DEVICE <<EOF
d
2
n
p
2
$R1_START
+${PARTITION_SIZE}
w
EOF

sleep 1

#there may be an unitialized 3MB sector at beginning, ergo we want to start root 2 explicitly after root1
R1_END=$(sudo fdisk -l $DEVICE | grep "^${DEVICE}2" | awk '{print $3}')

sudo fdisk $DEVICE <<EOF
n
p
3
$(($R1_END+1))

w
EOF

#inform kernel of new partition table
sudo partprobe $DEVICE
#check for errors
sudo e2fsck -f {$DEVICE}2
#resize fs for new size
sudo resize2fs {$DEVICE}2

# Format partitions
sudo mkfs.vfat -F 32 ${DEVICE}1  # Boot partition
Sudo mkfs.ext4 ${DEVICE}2  # Root partition 1

#format new partition to ext4
sudo mkfs.ext4 ${DEVICE}3  # Root partition 2

echo "Partitioning and formatting completed."