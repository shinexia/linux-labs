# build bzImage

linux version: v5.4

enable make logs

``` bash
make -j$(nproc) V=1
```

## bzImage

``` bash
arch/x86/boot/tools/build \
    arch/x86/boot/setup.bin \
    arch/x86/boot/vmlinux.bin \
    arch/x86/boot/zoffset.h \
    arch/x86/boot/bzImage
```

## arch/x86/boot/tools/build

``` bash
gcc -Wp,-MD,arch/x86/boot/tools/.build.d -Wall -Wmissing-prototypes -Wstrict-prototypes -O2 -fomit-frame-pointer -std=gnu89  \
    -I./tools/include -include include/generated/autoconf.h -D__EXPORTED_HEADERS__\
    -o arch/x86/boot/tools/build \
    arch/x86/boot/tools/build.c
```

## arch/x86/boot/setup.bin

``` bash
ld -m elf_x86_64  -z max-page-size=0x200000   -m elf_i386 \
    -T arch/x86/boot/setup.ld \
    arch/x86/boot/a20.o arch/x86/boot/bioscall.o \
    arch/x86/boot/cmdline.o arch/x86/boot/copy.o \
    arch/x86/boot/cpu.o arch/x86/boot/cpuflags.o \
    arch/x86/boot/cpucheck.o \
    arch/x86/boot/early_serial_console.o \
    arch/x86/boot/edd.o \
    arch/x86/boot/header.o \
    arch/x86/boot/main.o \
    arch/x86/boot/memory.o \
    arch/x86/boot/pm.o \
    arch/x86/boot/pmjump.o \
    arch/x86/boot/printf.o \
    arch/x86/boot/regs.o \
    arch/x86/boot/string.o \
    arch/x86/boot/tty.o \
    arch/x86/boot/video.o \
    arch/x86/boot/video-mode.o \
    arch/x86/boot/version.o \
    arch/x86/boot/video-vga.o \
    arch/x86/boot/video-vesa.o \
    arch/x86/boot/video-bios.o \
    -o arch/x86/boot/setup.elf
objcopy  -O binary arch/x86/boot/setup.elf arch/x86/boot/setup.bin
```

## arch/x86/boot/zoffset.h

``` bash
nm arch/x86/boot/compressed/vmlinux | \
    sed -n -e 's/^\([0-9a-fA-F]*\) [ABCDGRSTVW] \(startup_32\|startup_64\|efi32_stub_entry\|efi64_stub_entry\|efi_pe_entry\|input_data\|_end\|_ehead\|_text\|z_.*\)$/#define ZO_^B 0x^A/p' \
    > arch/x86/boot/zoffset.h
```

zoffset.h content

```
#define ZO__ehead 0x00000000000003b1
#define ZO__end 0x0000000000ada000
#define ZO__text 0x0000000000a9bc30
#define ZO_efi32_stub_entry 0x0000000000000190
#define ZO_efi64_stub_entry 0x0000000000000390
#define ZO_efi_pe_entry 0x00000000000002f0
#define ZO_input_data 0x00000000000003b1
#define ZO_startup_32 0x0000000000000000
#define ZO_startup_64 0x0000000000000200
#define ZO_z_input_len 0x0000000000a9b874
#define ZO_z_output_len 0x0000000002aedbec
```

## arch/x86/boot/vmlinux.bin

objcopy  -O binary -R .note -R .comment -S arch/x86/boot/compressed/vmlinux arch/x86/boot/vmlinux.bin

## arch/x86/boot/compressed/vmlinux

``` bash
for obj in arch/x86/boot/compressed/head_64.o \
    arch/x86/boot/compressed/misc.o \
    arch/x86/boot/compressed/string.o \
    arch/x86/boot/compressed/cmdline.o \
    arch/x86/boot/compressed/error.o \
    arch/x86/boot/compressed/piggy.o \
    arch/x86/boot/compressed/cpuflags.o \
    arch/x86/boot/compressed/early_serial_console.o \
    arch/x86/boot/compressed/kaslr.o \
    arch/x86/boot/compressed/kaslr_64.o \
    arch/x86/boot/compressed/mem_encrypt.o \
    arch/x86/boot/compressed/pgtable_64.o \
    arch/x86/boot/compressed/acpi.o \
    arch/x86/boot/compressed/eboot.o \
    arch/x86/boot/compressed/efi_stub_64.o \
    arch/x86/boot/compressed/efi_thunk_64.o ;
do
    readelf -S $obj | grep -qF .rel.local && { echo "error: $obj has data relocations!" >&2; exit 1; } || true; 
done;

ld -m elf_x86_64 -z noreloc-overflow -pie --no-dynamic-linker   \
    -T arch/x86/boot/compressed/vmlinux.lds \
    arch/x86/boot/compressed/head_64.o \
    arch/x86/boot/compressed/misc.o \
    arch/x86/boot/compressed/string.o \
    arch/x86/boot/compressed/cmdline.o \
    arch/x86/boot/compressed/error.o \
    arch/x86/boot/compressed/piggy.o \
    arch/x86/boot/compressed/cpuflags.o \
    arch/x86/boot/compressed/early_serial_console.o \
    arch/x86/boot/compressed/kaslr.o \
    arch/x86/boot/compressed/kaslr_64.o \
    arch/x86/boot/compressed/mem_encrypt.o \
    arch/x86/boot/compressed/pgtable_64.o \
    arch/x86/boot/compressed/acpi.o \
    arch/x86/boot/compressed/eboot.o \
    arch/x86/boot/compressed/efi_stub_64.o \
    drivers/firmware/efi/libstub/lib.a \
    arch/x86/boot/compressed/efi_thunk_64.o \
    -o arch/x86/boot/compressed/vmlinux
```

`readelf -S $obj | grep -qF .rel.local `

``` bash
$ readelf -S arch/x86/boot/compressed/head_64.o 
There are 12 section headers, starting at offset 0x1cb8:

Section Headers:
  [Nr] Name              Type             Address           Offset
       Size              EntSize          Flags  Link  Info  Align
  [ 0]                   NULL             0000000000000000  00000000
       0000000000000000  0000000000000000           0     0     0
  [ 1] .text             PROGBITS         0000000000000000  00000040
       00000000000001e1  0000000000000000  AX       0     0     16
  [ 2] .rela.text        RELA             0000000000000000  000015f0
       00000000000000d8  0000000000000018   I       9     1     8
  [ 3] .data             PROGBITS         0000000000000000  00000228
       00000000000000aa  0000000000000000  WA       0     0     8
  [ 4] .rela.data        RELA             0000000000000000  000016c8
       0000000000000048  0000000000000018   I       9     3     8
  [ 5] .bss              NOBITS           0000000000000000  000002d4
       0000000000014000  0000000000000000  WA       0     0     4
  [ 6] .head.text        PROGBITS         0000000000000000  000002e0
       00000000000003b1  0000000000000000  AX       0     0     16
  [ 7] .rela.head.text   RELA             0000000000000000  00001710
       0000000000000558  0000000000000018   I       9     6     8
  [ 8] .pgtable          NOBITS           0000000000000000  00001000
       0000000000012000  0000000000000000   A       0     0     4096
  [ 9] .symtab           SYMTAB           0000000000000000  00001000
       0000000000000438  0000000000000018          10    19     8
  [10] .strtab           STRTAB           0000000000000000  00001438
       00000000000001b7  0000000000000000           0     0     1
  [11] .shstrtab         STRTAB           0000000000000000  00001c68
       000000000000004f  0000000000000000           0     0     1
Key to Flags:
  W (write), A (alloc), X (execute), M (merge), S (strings), I (info),
  L (link order), O (extra OS processing required), G (group), T (TLS),
  C (compressed), x (unknown), o (OS specific), E (exclude),
  l (large), p (processor specific)
```

## arch/x86/boot/compressed/piggy.S

``` bash
arch/x86/boot/compressed/mkpiggy arch/x86/boot/compressed/vmlinux.bin.lz4 > arch/x86/boot/compressed/piggy.S
```

`piggy.S` content

``` asm
.section ".rodata..compressed","a",@progbits
.globl z_input_len
z_input_len = 11122804
.globl z_output_len
z_output_len = 45013996
.globl input_data, input_data_end
input_data:
.incbin "arch/x86/boot/compressed/vmlinux.bin.lz4"
input_data_end:
```

## arch/x86/boot/compressed/vmlinux.bin.lz4

``` bash
objcopy  -R .comment -S vmlinux arch/x86/boot/compressed/vmlinux.bin

arch/x86/tools/relocs vmlinux > arch/x86/boot/compressed/vmlinux.relocs; arch/x86/tools/relocs --abs-relocs vmlinux

{ cat arch/x86/boot/compressed/vmlinux.bin arch/x86/boot/compressed/vmlinux.relocs | lz4c -l -c1 stdin stdout; printf \354\333\256\002; } \
    > arch/x86/boot/compressed/vmlinux.bin.lz4

```

## vmlinux

``` bash
ld -m elf_x86_64 -z max-page-size=0x200000 -r \
    -o vmlinux.o \
    --whole-archive arch/x86/kernel/head_64.o \
    arch/x86/kernel/head64.o \
    arch/x86/kernel/ebda.o \
    arch/x86/kernel/platform-quirks.o \
    init/built-in.a \
    usr/built-in.a \
    arch/x86/built-in.a \
    kernel/built-in.a \
    certs/built-in.a \
    mm/built-in.a \
    fs/built-in.a \
    ipc/built-in.a \
    security/built-in.a \
    crypto/built-in.a \
    block/built-in.a \
    lib/built-in.a \
    arch/x86/lib/built-in.a \
    drivers/built-in.a \
    sound/built-in.a \
    samples/built-in.a \
    arch/x86/pci/built-in.a \
    arch/x86/power/built-in.a \
    arch/x86/video/built-in.a \
    net/built-in.a \
    virt/built-in.a \
    --no-whole-archive --start-group lib/lib.a arch/x86/lib/lib.a --end-group

scripts/mod/modpost  -a -o ./Module.symvers       vmlinux.o

objcopy -j .modinfo -O binary vmlinux.o modules.builtin.modinfo

ld -m elf_x86_64 -z max-page-size=0x200000 --emit-relocs --discard-none --build-id \
    -o .tmp_vmlinux1 \
    -T ./arch/x86/kernel/vmlinux.lds \
    --whole-archive arch/x86/kernel/head_64.o \
     arch/x86/kernel/head64.o \
     arch/x86/kernel/ebda.o \
     arch/x86/kernel/platform-quirks.o \
     init/built-in.a usr/built-in.a \
     arch/x86/built-in.a \
     kernel/built-in.a \
     certs/built-in.a \
     mm/built-in.a \
     fs/built-in.a \
     ipc/built-in.a \
     security/built-in.a \
     crypto/built-in.a \
     block/built-in.a \
     lib/built-in.a \
     arch/x86/lib/built-in.a \
     drivers/built-in.a \
     sound/built-in.a \
     samples/built-in.a \
     arch/x86/pci/built-in.a \
     arch/x86/power/built-in.a \
     arch/x86/video/built-in.a \
     net/built-in.a \
     virt/built-in.a \
     --no-whole-archive --start-group lib/lib.a arch/x86/lib/lib.a --end-group

ld -m elf_x86_64 -z max-page-size=0x200000 --emit-relocs --discard-none --build-id \
    -o .tmp_vmlinux2 \
    -T ./arch/x86/kernel/vmlinux.lds -\
    -whole-archive arch/x86/kernel/head_64.o \
    arch/x86/kernel/head64.o \
    arch/x86/kernel/ebda.o \
    arch/x86/kernel/platform-quirks.o \
    init/built-in.a \
    usr/built-in.a \
    arch/x86/built-in.a \
    kernel/built-in.a \
    certs/built-in.a \
    mm/built-in.a \
    fs/built-in.a \
    ipc/built-in.a \
    security/built-in.a \
    crypto/built-in.a \
    block/built-in.a \
    lib/built-in.a \
    arch/x86/lib/built-in.a \
    drivers/built-in.a \
    sound/built-in.a \
    samples/built-in.a \
    arch/x86/pci/built-in.a \
    arch/x86/power/built-in.a \
    arch/x86/video/built-in.a \
    net/built-in.a \
    virt/built-in.a \
    --no-whole-archive --start-group lib/lib.a arch/x86/lib/lib.a --end-group \
    .tmp_kallsyms1.o

ld -m elf_x86_64 -z max-page-size=0x200000 --emit-relocs --discard-none --build-id \
    -o vmlinux \
    -T ./arch/x86/kernel/vmlinux.lds \
    --whole-archive \
    arch/x86/kernel/head_64.o \
    arch/x86/kernel/head64.o \
    arch/x86/kernel/ebda.o \
    arch/x86/kernel/platform-quirks.o \
    init/built-in.a \
    usr/built-in.a \
    arch/x86/built-in.a \
    kernel/built-in.a \
    certs/built-in.a \
    mm/built-in.a \
    fs/built-in.a \
    ipc/built-in.a \
    security/built-in.a \
    crypto/built-in.a \
    block/built-in.a \
    lib/built-in.a \
    arch/x86/lib/built-in.a \
    drivers/built-in.a \
    sound/built-in.a \
    samples/built-in.a \
    arch/x86/pci/built-in.a \
    arch/x86/power/built-in.a \
    arch/x86/video/built-in.a \
    net/built-in.a \
    virt/built-in.a --no-whole-archive --start-group lib/lib.a arch/x86/lib/lib.a --end-group \
    .tmp_kallsyms2.o

./scripts/sortextable vmlinux

./scripts/mksysmap vmlinux System.map

sed 's/ko$/o/' modules.order | scripts/mod/modpost  -a -o ./Module.symvers        -s -T - vmlinux
```
