/* linker.ld — 16-bit flat binary linker script for BIOS boot sector */

OUTPUT_FORMAT("elf64-x86-64")
ENTRY(_entry)

SECTIONS
{
    . = 0x9000;

    __top = .;

    .stage2_header :
    {
        *(.stage2_header*)
    }

    . = 0x9200;

    __load = .;

    .data16 :
    {
        *(.data16*)
    }

    .text :
    {
        *(.text*)
    }

    .rodata :
    {
        *(.rodata)
    }

    .data :
    {
        *(.data)
    }

    .init : { KEEP(*(.init)) }
    .fini : { KEEP(*(.fini)) }

    .init_array : ALIGN(8) {
    __init_array_start = .;
    KEEP(*(.init_array .init_array.*))
    KEEP(*(.ctors .ctors.*))    /* legacy */
    __init_array_end = .;
    }
    .fini_array : ALIGN(8) {
    __fini_array_start = .;
    KEEP(*(.fini_array .fini_array.*))
    KEEP(*(.dtors .dtors.*))
    __fini_array_end = .;
    }

    __end = .;


    __bss_start = .;
    .bss(NOLOAD) :
    {
        *(COMMON)
        *(.bss*)
        . = ALIGN(4);
    }
    __bss_end = .;
    __bss_size = __bss_end - __bss_start;

    __size = __end - __load;
    __sectors = (__size + 511) / 512;

}
