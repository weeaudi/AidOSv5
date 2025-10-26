; stage1.asm — minimal 16-bit BIOS bootloader test
; Assembled to ELF, linked to 0x7C00, then objcopied to a flat binary.
; It just prints a short message using BIOS teletype and halts.

BITS 16

GLOBAL _start

SECTION .text
_start:
    ret

SECTION .rodata
msg: db "Stage1 (16-bit) test OK!", 13, 10, 0

SECTION .bss
partition_data: resb 16
