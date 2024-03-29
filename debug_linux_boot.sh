#!/bin/bash

cd $(dirname $0) || exit $?

LROOT=$(pwd)
JOBCOUNT=${JOBCOUNT=$(nproc)}

export ARCH=x86_64
export INSTALL_PATH=${LROOT}/_install_boot_${ARCH}

LINUX_DIR=${LROOT}/linux

build_kernel() {
    cd ${LINUX_DIR}
    cp /boot/config-$(uname -r) .config
    make oldconfig      # 根据提示安装`flex bison libelf-dev`等依赖包
    make localmodconfig # 仅安装已有的module
    make menuconfig
    make -j${JOBCOUNT} V=1
    # got arch/x86_64/boot/bzImage
}

install_headers() {
    cd ${LINUX_DIR}
    make headers_install ARCH=${ARCH} INSTALL_HDR_PATH=${INSTALL_PATH}
}

# clean up *.o *.o.cmd files to get better reading
clean_kernel() {
    cd ${LINUX_DIR}
    find . -name \*.o -exec rm -v {} \;
    find . -regex '.*\.[^/]*\.cmd' -exec rm -v {} \;
}

run_qemu() {
    cd ${LINUX_DIR}
    qemu-system-i386 arch/x86_64/boot/bzImage -nographic -s -S
    # ctrl A + x to EXIT
}

run_gdb() {
    gdb -ex "target remote :1234" \
        -ex "set tdesc filename target.xml" \
        -ex "set arch i8086" \
        -ex "display/i \$cs*16+\$pc" \
        -ex "break *0x7c00"
}

case $1 in

build)
    build_kernel
    ;;

install)
    install_headers
    ;;

clean)
    clean_kernel
    ;;

run)
    run_qemu
    ;;

gdb)
    run_gdb
    ;;

*)
    echo "usage: $0 build|install|clean|run|gdb"
    exit 1
    ;;

esac
