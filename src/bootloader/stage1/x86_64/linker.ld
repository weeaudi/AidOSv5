/* linker.ld — 16-bit flat binary linker script for BIOS boot sector */

OUTPUT_FORMAT("elf32-i386")
ENTRY(_start)

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
 
    . = 0x7C00 + 510;
    .boot_sig : { SHORT(0xAA55) }
    
    ASSERT(SIZEOF(.text) + SIZEOF(.rodata) + SIZEOF(.data) <= 510,
         "Stage1 exceeds 510 bytes before signature")

    .bss(NOLOAD) :
    {
        *(COMMON)
        *(.bss*)
        . = ALIGN(4);
    }
    
}
