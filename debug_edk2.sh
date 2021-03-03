#!/bin/bash

cd $(dirname $) || exit $?

LROOT=$PWD
JOBCOUNT=${JOBCOUNT=$(nproc)}

export ARCH=x86_64
export INSTALL_PATH=${LROOT}/_install_edk2_$ARCH

EDK2_DIR=${LROOT}/edk2

build_img() {
    mkdir -p ${INSTALL_PATH}
}

build_base_tools() {
    cd ${EDK2_DIR}
    make -C BaseTools -j${JOBCOUNT}
    . ./edksetup.sh
}

build_helloworld() {
    build_img
    cd ${EDK2_DIR}
    rm -rfv Build/MdeModule
    . ./edksetup.sh
    build -a X64 -p MdeModulePkg/MdeModulePkg.dsc -t GCC5 -D SOURCE_DEBUG_ENABLE
    cp -v Build/MdeModule/DEBUG_GCC5/X64/HelloWorld.* ${INSTALL_PATH}
}

build_ovmf() {
    build_img
    cd ${EDK2_DIR}
    rm -rfv Build/Ovmf
    . ./edksetup.sh
    build -a X64 -p OvmfPkg/OvmfPkgX64.dsc -t GCC5 -D SOURCE_DEBUG_ENABLE
    cp -v Build/OvmfX64/DEBUG_GCC5/FV/OVMF*.fd ${INSTALL_PATH}
}

run_ovmf() {
    qemu-system-${ARCH} \
        -pflash ${INSTALL_PATH}/OVMF.fd \
        -hda fat:rw:${INSTALL_PATH} \
        -net none \
        -debugcon file:${INSTALL_PATH}/debug.log \
        -global isa-debugcon.iobase=0x402 \
        -nographic -s
}

run_gdb() {
    cd ${GRUB2_DIR}/grub-core
    gdb --tui -x gdb_grub \
        -ex "display/i \$pc"
}

case $1 in

build_img)
    build_img
    ;;

build_base_tools)
    build_base_tools
    ;;

build_helloworld)
    build_helloworld
    ;;

build_ovmf)
    build_ovmf
    ;;

run_ovmf)
    run_ovmf
    ;;

gdb)
    run_gdb
    ;;

*)
    echo "usage: $0 build_grub2|build_img|run|gdb"
    exit 1
    ;;

esac
