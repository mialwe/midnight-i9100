#!/sbin/busybox sh

BB='/sbin/busybox'
$BB cp /data/user.log /data/user.log.bak
$BB rm /data/user.log
exec >>/data/user.log
exec 2>&1

# remount
$BB mount -o remount,rw /system
$BB mount -t rootfs -o remount,rw rootfs

# mount options
for k in $(mount | grep relatime | cut -d " " -f3);do
    $BB mount -o remount,noatime,nodiratime,noauto_da_alloc,barrier=0 $k
done

# read_ahead
echo 128 > /sys/block/mmcblk0/bdi/read_ahead_kb
echo 128 > /sys/block/mmcblk1/bdi/read_ahead_kb

# logger compiled into the kernel for now...
# insmod /lib/modules/logger.ko

# the end
$BB mount -t rootfs -o remount,ro rootfs
$BB mount -o remount,ro /system

exit 0
