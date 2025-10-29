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

    /* need 16bit code at top of the file */
    .text16 :
    {
        *(.text16*)
    }

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
        *(.rodata*)
    }

    .data :
    {
        *(.data*)
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
