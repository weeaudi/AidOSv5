/* linker.ld — 16-bit flat binary linker script for BIOS boot sector */

OUTPUT_FORMAT("elf32-i386")
ENTRY(_entry)

SECTIONS
{
    . = 0xA000;


    .stage2_header :
    {
        *(.stage2_header*)
    }

    . = 0x10200;

    __load = .;

    .text :
    {
        *(.text*)
    }

    .rodata :
    {
        *(.rodata*)
    }

    .data :
    {
        *(.data*)
    }

    __end = .;

    .bss :
    {
        *(COMMON)
        *(.bss*)
        . = ALIGN(4);
    }

    __size = __end - __load;
    __sectors = (__size + 511) / 512;

}
