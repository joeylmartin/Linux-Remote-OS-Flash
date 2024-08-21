#Linux Remote Flash OS Scripts

This is is an example of using partitions to enable remote flashing of an OS running Linux. 

They work on the premise of using partitions: a boot partition points to a root partition to run the OS. The remote flashing allows an OS to operate while writing to an extra unused partition. The boot partition can than be edited to point to the other root partition, and reboot. 
This is a far more reliable approach to live OS flashing (e.g attempting to store a script entirely in EEPROM while writing).

The one cost to this approach is that the disk has to already have the partitions initalized. Use the included `initialize_partitions.bash` script to flash the disk the initial time.

The included `install_and_swap_os.bash` script takes a .img file and the disk location (likely `/dev/mmcblk0`) as arguments. To invoke it, using an SSH instance (along an SCP transfer of the OS image) is the simplest approach. However, it could also be wrapped in an script to make it client-side something along the lines of: 

>
 >poll_endpoint() {
 >  If poll server == true:
 >       wget -O /tmp/image.img image url
 >       install_and_swap_os /tmp/image.img /dev/mmcblk0
 >   else:
 >       sleep 5
 >       poll_endpoint
>}

etc etc.


This is free to use for inspiration, or direct copying.