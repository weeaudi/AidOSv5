; stage1.asm — minimal 16-bit BIOS bootloader test
; Assembled to ELF, linked to 0x7C00, then objcopied to a flat binary.
; It just prints a short message using BIOS teletype and halts.

BITS 16

GLOBAL _start

SECTION .text
_start:
    cli                     ; Disable interrupts
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00          ; simple stack near load addr

    mov si, msg
    call print_string

hang:
    hlt
    jmp hang

; -------------------------------------------------------------
; BIOS teletype print routine (INT 0x10 / AH=0x0E)
; -------------------------------------------------------------
print_string:
    mov ah, 0x0E
.next_char:
    lodsb                   ; load next byte from [SI] into AL
    test al, al
    jz .done
    int 0x10
    jmp .next_char
.done:
    ret

SECTION .rodata
msg:
    db "Stage1 (16-bit) test OK!", 13, 10, 0
