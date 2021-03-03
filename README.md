# linux-labs

linux labs

## Requirements

Ubuntu 20.04 x86_64

kernel <https://wiki.ubuntu.com/Kernel/BuildYourOwnKernel>

``` bash
sudo apt install libncurses-dev gawk flex bison openssl libssl-dev dkms libelf-dev libudev-dev libpci-dev libiberty-dev autoconf
```

qemu (ref: running linux kernel)

``` bash
sudo apt install qemu qemu-system-arm gcc-aarch64-linux-gnu gdb-multiarch bc trace-cmd kernelshark bpfcc-tools cppcheck
sudo apt install ovmf ksmtuned
```

grub2

``` bash
sudo apt install libdevmapper-dev autopoint libsdl2-dev libpciaccess-dev libusb-dev libfreetype-dev unifont xorriso libfuse-dev fonts-dejavu zfsutils-linux
```

edk2

``` bash
sudo apt install nasm iasl
```

