#!/sbin/busybox sh

BB='/sbin/busybox'
$BB cp /data/user.log /data/user.log.bak
$BB rm /data/user.log
exec >>/data/user.log
exec 2>&1

# remount
$BB mount -o remount,rw /system
$BB mount -t rootfs -o remount,rw rootfs

# start logfile output
echo
echo "************************************************"
echo "MIDNIGHT-I9100 BOOT LOG"
echo "************************************************"
echo
echo "$(date)"
echo

# log basic system information
echo -n "Kernel: ";$BB uname -r
echo -n "PATH: ";echo $PATH
echo -n "ROM: ";cat /system/build.prop|$BB grep ro.build.display.id
echo -n "BusyBox:";$BB|$BB grep BusyBox

echo;echo "$(date) modules"
ls -l /lib/modules

echo;echo "$(date) modules loaded"
$BB lsmod
echo

# print file contents <string messagetext><file output>
cat_msg_sysfile() {
    MSG=$1
    SYSFILE=$2
    echo -n "$MSG"
    cat $SYSFILE
}

# partitions
echo; echo "$(date) mount"
for i in $($BB mount | $BB grep relatime | $BB cut -d " " -f3);do
    $BB mount -o remount,noatime $i
done
$BB mount

# read_ahead
echo; echo "$(date) read_ahead"
echo 128 > /sys/block/mmcblk0/bdi/read_ahead_kb
echo 128 > /sys/block/mmcblk1/bdi/read_ahead_kb

# logger compiled into the kernel for now...
# insmod /lib/modules/logger.ko

# vm tweaks
echo; echo "$(date) vm"
echo "0" > /proc/sys/vm/swappiness # Not really needed as no /swap used...
echo "1500" > /proc/sys/vm/dirty_writeback_centisecs # Flush after 20sec. (o:500)
echo "1500" > /proc/sys/vm/dirty_expire_centisecs # Pages expire after 20sec. (o:200)
echo "5" > /proc/sys/vm/dirty_background_ratio # flush pages later (default 5% active mem)
echo "15" > /proc/sys/vm/dirty_ratio # process writes pages later (default 20%)
echo "3" > /proc/sys/vm/page-cluster
echo "0" > /proc/sys/vm/laptop_mode
echo "0" > /proc/sys/vm/oom_kill_allocating_task
echo "0" > /proc/sys/vm/panic_on_oom
echo "1" > /proc/sys/vm/overcommit_memory
cat_msg_sysfile "swappiness: " /proc/sys/vm/swappiness
cat_msg_sysfile "dirty_writeback_centisecs: " /proc/sys/vm/dirty_writeback_centisecs
cat_msg_sysfile "dirty_expire_centisecs: " /proc/sys/vm/dirty_expire_centisecs
cat_msg_sysfile "dirty_background_ratio: " /proc/sys/vm/dirty_background_ratio
cat_msg_sysfile "dirty_ratio: " /proc/sys/vm/dirty_ratio
cat_msg_sysfile "page-cluster: " /proc/sys/vm/page-cluster
cat_msg_sysfile "laptop_mode: " /proc/sys/vm/laptop_mode
cat_msg_sysfile "oom_kill_allocating_task: " /proc/sys/vm/oom_kill_allocating_task
cat_msg_sysfile "panic_on_oom: " /proc/sys/vm/panic_on_oom
cat_msg_sysfile "overcommit_memory: " /proc/sys/vm/overcommit_memory

# security enhancements
# rp_filter must be reset to 0 if TUN module is used (issues)
echo; echo "$(date) sec"
echo 0 > /proc/sys/net/ipv4/ip_forward
echo 0 > /proc/sys/net/ipv4/conf/all/rp_filter
echo 2 > /proc/sys/net/ipv6/conf/all/use_tempaddr
echo 0 > /proc/sys/net/ipv4/conf/all/accept_source_route
echo 0 > /proc/sys/net/ipv4/conf/all/send_redirects
echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts
echo -n "SEC: ip_forward :";cat /proc/sys/net/ipv4/ip_forward
echo -n "SEC: rp_filter :";cat /proc/sys/net/ipv4/conf/all/rp_filter
echo -n "SEC: use_tempaddr :";cat /proc/sys/net/ipv6/conf/all/use_tempaddr
echo -n "SEC: accept_source_route :";cat /proc/sys/net/ipv4/conf/all/accept_source_route
echo -n "SEC: send_redirects :";cat /proc/sys/net/ipv4/conf/all/send_redirects
echo -n "SEC: icmp_echo_ignore_broadcasts :";cat /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts

# setprop tweaks
echo; echo "$(date) prop"
setprop wifi.supplicant_scan_interval 180
echo -n "wifi.supplicant_scan_interval (is this actually used?): ";getprop wifi.supplicant_scan_interval

# kernel tweaks
echo; echo "$(date) kernel"
echo 500 512000 64 2048 > /proc/sys/kernel/sem
echo 3000000 > /proc/sys/kernel/sched_latency_ns
echo 500000 > /proc/sys/kernel/sched_wakeup_granularity_ns
echo 500000 > /proc/sys/kernel/sched_min_granularity_ns
echo 0 > /proc/sys/kernel/panic_on_oops
echo 0 > /proc/sys/kernel/panic
cat_msg_sysfile "sched_features: " /sys/kernel/debug/sched_features
cat_msg_sysfile "sem: " /proc/sys/kernel/sem;
cat_msg_sysfile "sched_latency_ns: " /proc/sys/kernel/sched_latency_ns
cat_msg_sysfile "sched_wakeup_granularity_ns: " /proc/sys/kernel/sched_wakeup_granularity_ns
cat_msg_sysfile "sched_min_granularity_ns: " /proc/sys/kernel/sched_min_granularity_ns
cat_msg_sysfile "panic_on_oops: " /proc/sys/kernel/panic_on_oops
cat_msg_sysfile "panic: " /proc/sys/kernel/panic

# the end
$BB mount -t rootfs -o remount,ro rootfs
$BB mount -o remount,ro /system

exit 0
