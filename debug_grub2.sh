#!/bin/bash

cd $(dirname $0) || exit $?

LROOT=$PWD
JOBCOUNT=${JOBCOUNT=$(nproc)}

export ARCH=x86_64
export INSTALL_PATH=${LROOT}/_install_grub2_${ARCH}
export BOOT_INSTALL_PATH=${LROOT}/_install_boot_${ARCH}

LINUX_DIR=${LROOT}/linux
GRUB2_DIR=${LROOT}/grub2
HDA_IMG_FILE=${INSTALL_PATH}/grub2-hda.img

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
    if [[ -f "${HDA_IMG_FILE}" ]]; then
        rm -v ${HDA_IMG_FILE}
    fi
    qemu-img create -f raw ${HDA_IMG_FILE} 512M
    mkfs.fat ${HDA_IMG_FILE}
    sudo mount -o uid=$UID ${HDA_IMG_FILE} /mnt
    mkdir -p /mnt/efi/boot
    ${INSTALL_PATH}/bin/grub-mkstandalone -O x86_64-efi -o /mnt/efi/boot/bootx64.efi
    sudo umount /mnt

    mkdir -p ${BOOT_INSTALL_PATH} &&
        ${INSTALL_PATH}/bin/grub-mkstandalone -O x86_64-efi -o ${BOOT_INSTALL_PATH}/grubx64.efi
}

run_qemu() {
    qemu-system-${ARCH} \
        -bios /usr/share/ovmf/OVMF.fd \
        -hda ${HDA_IMG_FILE} \
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

build)
    build_grub2
    build_img
    ;;

run)
    run_qemu
    ;;

gdb)
    run_gdb
    ;;

*)
    echo "usage: $0 build|run|gdb"
    exit 1
    ;;

esac
