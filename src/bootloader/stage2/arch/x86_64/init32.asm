; ------------------------------------------------------------------
; AIDOS 32 bit initialization - sets up and enables protected mode
; ------------------------------------------------------------------

BITS 16

%define SEL_NULL 0x00
%define SEL_CODE 0x08
%define SEL_DATA 0x10

GLOBAL init_32

SECTION .text

; Switches to proteted mode then jumps to address pushed to stack
init_32:

    cli
    call enable_a20

    pop ax
    push word SEL_CODE
    push ax

    lgdt [gdt.Pointer]

    mov eax, cr0
    or  eax, 1                  ; PE=1
    mov cr0, eax

    retf


; From the OSDEV wiki
enable_a20:
    cli

    call    a20wait
    mov     al,0xAD
    out     0x64,al

    call    a20wait
    mov     al,0xD0
    out     0x64,al

    call    a20wait2
    in      al,0x60
    push    eax

    call    a20wait
    mov     al,0xD1
    out     0x64,al

    call    a20wait
    pop     eax
    or      al,2
    out     0x60,al

    call    a20wait
    mov     al,0xAE
    out     0x64,al

    sti
    ret

a20wait:
    in      al,0x64
    test    al,2
    jnz     a20wait
    ret


a20wait2:
    in      al,0x64
    test    al,1
    jz      a20wait2
    ret

SECTION .data16

; Access bits
    PRESENT:        equ 1 << 7
    NOT_SYS:        equ 1 << 4
    EXEC:           equ 1 << 3
    DC:             equ 1 << 2
    RW:             equ 1 << 1
    ACCESSED:       equ 1 << 0

; Flags bits
    GRAN_4K:       equ 1 << 7
    SZ_32:         equ 1 << 6
    LONG_MODE:     equ 1 << 5

gdt:
.Null: equ $ - gdt
    dq 0
.Code: equ $ - gdt
    .Code.limit_lo: dw 0xffff
    .Code.base_lo: dw 0
    .Code.base_mid: db 0
    .Code.access: db PRESENT | NOT_SYS | EXEC | RW
    .Code.flags: db GRAN_4K | SZ_32 | 0xF   ; Flags & Limit (high, bits 16-19)
    .Code.base_hi: db 0
.Data: equ $ - gdt
    .Data.limit_lo: dw 0xffff
    .Data.base_lo: dw 0
    .Data.base_mid: db 0
    .Data.access: db PRESENT | NOT_SYS | RW
    .Data.Flags: db GRAN_4K | SZ_32 | 0xF       ; Flags & Limit (high, bits 16-19)
    .Data.base_hi: db 0
.Pointer:
    dw $ - gdt - 1
    dq gdt