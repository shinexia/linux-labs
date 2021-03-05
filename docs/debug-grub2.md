# debug grub2

## steps

1. build edk2 to get a debug-enabled UEFI BIOS fd

``` bash
./debug_edk2.sh build
```

got `_install_boot_x86_64/OVMF.fd`

1. build grub2

``` bash 
./debug_grub2.sh build
```

got `_install_boot_x86_64/grubx64.efi`


3. run `grubx64.efi` in UEFI BIOS with debug log

``` bash
./debug-edk2.sh run
```

then type in:

``` bash
Shell\> fs0:
FS0:\> grubx64.efi
```

will got logs in `_install_boot_x86_64/debug.log` like:

``` text
FSOpen: Open '\grubx64.efi' Success
[Security] 3rd party image[0] can be loaded after EndOfDxe: PciRoot(0x0)/Pci(0x1,0x1)/Ata(Primary,Master,0x0)/HD(1,MBR,0xBE1AFDFA,0x3F,0xFBFC1)/\grubx64.efi.
InstallProtocolInterface: 5B1B31A1-9562-11D2-8E3F-00A0C969723B 6C2D140
Loading driver at 0x0000519F000 EntryPoint=0x000051A0000 
InstallProtocolInterface: BC62157E-3E33-4FEC-9920-2D3B36D750DF 6C36D98
ProtectUefiImageCommon - 0x6C2D140
  - 0x000000000519F000 - 0x0000000000979000
InstallProtocolInterface: 752F3136-4E16-4FDC-A22A-E5F46812F4CA 7EA36C8
```

this line `Loading driver at 0x0000519F000 EntryPoint=0x000051A0000` is what we want

then type `exit` to EXIT grub2

4. run gdb in another terminal

``` bash
./debug-edk2.sh gdb
```

then

``` bash
(gdb) file ../../_install_boot_x86_64/grubx64.efi
A program is being debugged already.
Are you sure you want to change the file? (y or n) y
Reading symbols from ../../_install_boot_x86_64/grubx64.efi...
(No debugging symbols found in ../../_install_boot_x86_64/grubx64.efi)
(gdb) info files
Symbols from "/home/shine/work/github/linux-labs/_install_boot_x86_64/grubx64.efi".
Remote serial target in gdb-specific protocol:
Debugging a target over a serial line.
        While running this, GDB does not access memory from...
Local exec file:
        `/home/shine/work/github/linux-labs/_install_boot_x86_64/grubx64.efi', file type pei-x86-64.
        Entry point: 0x1000
        0x0000000000001000 - 0x000000000000c000 is .text
        0x000000000000c000 - 0x000000000001c000 is .data
        0x000000000001c000 - 0x0000000000978000 is mods
        0x0000000000978000 - 0x0000000000979000 is .reloc
```

following is what we want

``` text
0x0000000000001000 - 0x000000000000c000 is .text
0x000000000000c000 - 0x000000000001c000 is .data
```

text = `0x0000519F000 + 1000 = 0x51A0000`

data = `0x0000519F000 + 1000 + c000 = 0x51AC000`

again in gdb

``` bash
(gdb) add-symbol-file kernel.exec 0x51A0000 -s .data 0x51AC000
add symbol table from file "kernel.exec" at
        .text_addr = 0x51a0000
        .data_addr = 0x51ac000
(y or n) y
Reading symbols from kernel.exec...
(gdb) break _start
Note: breakpoints 1 and 2 also set at pc 0x51a0000.
Breakpoint 4 at 0x51a0000: file startup.S, line 30.
(gdb) break grub_main
Note: breakpoint 3 also set at pc 0x51a7cca.
Breakpoint 5 at 0x51a7cca: file kern/main.c, line 266.
(gdb) c
Continuing.
```

in edk2 (now running grub2) type `exit` to exit grub2 and type `grubx64.efi` to run grub2 again, in gdb you will see:

``` bash
Breakpoint 1, start () at startup.S:30
startup.S: No such file or directory.
(gdb) display/i $pc
1: x/i $pc
=> 0x51a0000 <start>:   mov    %rcx,0xfef1(%rip)        # 0x51afef8
(gdb) si
1: x/i $pc
=> 0x51a0007 <start+7>: mov    %rdx,0xfee2(%rip)        # 0x51afef0
startup.S: No such file or directory.
(gdb) si
1: x/i $pc
=> 0x51a000e <start+14>:        and    $0xfffffffffffffff0,%rsp
startup.S: No such file or directory.
(gdb) si
start () at startup.S:34
1: x/i $pc
=> 0x51a0012 <start+18>:        callq  0x51a7cca <grub_main>
startup.S: No such file or directory.
(gdb) si

Breakpoint 3, grub_main () at kern/main.c:266
1: x/i $pc
=> 0x51a7cca <grub_main>:       endbr64
```

boot path

```
_start: grub2/grub-core/kern/i386/efi/startup.S
grub_main: grub2/grub-core/kern/main.c
```

startup.S

``` asm
#include <config.h>
#include <grub/symbol.h>

        .file   "startup.S"
        .text
        .globl  start, _start
start:
_start:
	/*
	 *  EFI_SYSTEM_TABLE * and EFI_HANDLE are passed on the stack.
	 */
	movl	4(%esp), %eax
	movl	%eax, EXT_C(grub_efi_image_handle)
	movl	8(%esp), %eax
	movl	%eax, EXT_C(grub_efi_system_table)
	call	EXT_C(grub_main)
	ret
```

linux boot commands(linux, initrd, boot etc.)

``` text
grub2/grub-core/loader/i386/linux.c
```

a minimal linux bootloader: [../mlb](../mlb)

5. do what you want


## links

1. <https://stackoverflow.com/questions/43872078/debug-grub2-efi-image-running-on-qemu>
2. <https://github.com/tianocore/tianocore.github.io/wiki/How-to-debug-OVMF-with-QEMU-using-GDB>

