#!/bin/bash

cd $(dirname $0) || exit $?

LROOT=$PWD
JOBCOUNT=${JOBCOUNT=$(nproc)}
LINUX_DIR=linux
BUSYBOX_DIR=busybox

export ARCH=x86_64
export INSTALL_PATH=${LROOT}/_install_busybox_$ARCH

SMP="-smp 4"
if [[ "$@" =~ "debug" ]]; then
    DBG="-s -S"
    SMP=""
fi

build_busybox() {
    rm -vfr ${INSTALL_PATH}
    cd ${BUSYBOX_DIR}
    make menuconfig
    make -j${JOBCOUNT}
    make install
    mv _install ${INSTALL_PATH}
}

build_rootfs() {
    if [[ ! -d ${INSTALL_PATH} ]]; then
        build_busybox
    fi

    cd ${INSTALL_PATH} || exit $?
    mkdir -p etc/init.d
    mkdir -p dev
    mkdir -p mnt

    tee etc/init.d/rcS <<-'EOF'
mkdir -p /proc 
mkdir -p /tmp 
mkdir -p /sys
/bin/mount -a
mkdir -p /dev/pts
mount -t devpts devpts /dev/pts
echo /sbin/mdev > /proc/sys/kernel/hotplug
mdev -s
EOF
    chmod a+x etc/inid.d/rcS

    tee etc/fstab <<-'EOF'
proc    /proc             proc    defaults 0 0
tmpfs   /tmp              tmpfs   defaults 0 0
sysfs   /sys              sysfs   defaults 0 0
tmpfs   /dev              tmpfs   defaults 0 0
debugfs /sys/kernel/debug debugfs defaults 0 0
EOF

    tee etc/inittab <<-'EOF'
::sysinit:/etc/init.d/rcS
::respawn:-/bin/sh
::askfirst:-/bin/sh
::ctrlaltdel:/bin/umount -a -r
EOF

    cd ${INSTALL_PATH}/dev || exit $?
    sudo mknod console c 5 1
    sudo mknod null c 1 3
}

run_qemu() {
    qemu-system-${ARCH} -m 256M \
        -nographic $SMP \
        -kernel ${LINUX_DIR}/arch/${ARCH}/boot/bzImage \
        -append "rdinit=/linuxrc console=ttyAMA0 loglevel=8" \
        -netdev user,id=mynet -device virtio-net-pci,netdev=mynet --fsdev local,id=kmod_dev,path=./kmodules,security_model=none \
        $DBG
}

case $1 in
build_busybox)
    build_busybox
    ;;
build_rootfs)
    build_rootfs
    ;;
run)
    run_qemu
    ;;
*)
    echo "usage: $0 build_busybox"
    exit 1
    ;;
esac
