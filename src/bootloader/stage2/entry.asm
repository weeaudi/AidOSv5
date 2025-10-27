BITS 16

GLOBAL _entry

SECTION .text

_entry:

.loop:
    jmp .loop
    ret