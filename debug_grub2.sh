#!/bin/bash

cd $(dirname $) || exit $?

LROOT=$PWD
JOBCOUNT=${JOBCOUNT=$(nproc)}

export ARCH=x86_64
export INSTALL_PATH=${LROOT}/_install_grub2_${ARCH}
export EDK2_INSTALL_PATH=${LROOT}/_install_edk2_${ARCH}

LINUX_DIR=${LROOT}/linux
GRUB2_DIR=${LROOT}/grub2
IMG_PATH=${INSTALL_PATH}/hda.img

build_grub2() {
    rm -vfr ${INSTALL_PATH}
    cd ${GRUB2_DIR}
    ./linguas.sh
    ./bootstrap
    ./configure --with-platform=efi --prefix=${INSTALL_PATH} CFLAGS=-g
    make -j${JOBCOUNT}
    make install
    #make check -j${JOBCOUNT}
}

build_img() {
    if [[ -f "${IMG_PATH}" ]]; then
        rm -v ${IMG_PATH}
    fi
    qemu-img create -f raw ${IMG_PATH} 512M
    mkfs.fat ${IMG_PATH}
    sudo mount -o uid=$UID ${IMG_PATH} /mnt
    mkdir -p /mnt/efi/boot
    ${INSTALL_PATH}/bin/grub-mkstandalone -O x86_64-efi -o /mnt/efi/boot/bootx64.efi
    ${INSTALL_PATH}/bin/grub-mkstandalone -O x86_64-efi -o ${EDK2_INSTALL_PATH}/grubx64.efi
    sudo umount /mnt
}

run_qemu() {
    qemu-system-${ARCH} \
        -bios /usr/share/ovmf/OVMF.fd \
        -hda ${IMG_PATH} \
        -nographic -s -S
}

run_gdb() {
    cd ${GRUB2_DIR}/grub-core
    gdb --tui -x gdb_grub \
        -ex "display/i \$pc"
}

case $1 in

build_grub2)
    build_grub2
    ;;

build_img)
    build_img
    ;;

run)
    run_qemu
    ;;

gdb)
    run_gdb
    ;;

*)
    echo "usage: $0 build_grub2|build_img|run|gdb"
    exit 1
    ;;

esac
