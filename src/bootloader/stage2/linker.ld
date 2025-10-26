/* linker.ld — 16-bit flat binary linker script for BIOS boot sector */

OUTPUT_FORMAT("elf32-i386")
ENTRY(aidos_stage2_main)

SECTIONS
{
    /* BIOS loads stage1 at 0x7C00 */
    . = 0x7C00;

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

    .bss :
    {
        *(COMMON)
        *(.bss*)
        . = ALIGN(4);
    }
}
