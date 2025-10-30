; ------------------------------------------------------------------
; AIDOS 64 bit initialization - setsup and enables long mode
; ------------------------------------------------------------------

BITS 32

GLOBAL init_64

SECTION .text

%define SEL_NULL 0x00
%define SEL_CODE 0x08
%define SEL_DATA 0x10

init_64:
    call setup_paging

    pop eax
    push word SEL_CODE
    push eax

    lgdt [gdt.Pointer]

    retf

setup_paging:

    call init_tables

    mov edi, PLM4
    mov cr3, edi

    mov eax, cr4
    or  eax, 1 << 5        ; ENABLE PAE
    mov cr4, eax

    ; enable LME
    mov ecx, 0xC0000080    ; IA32_EFER
    rdmsr
    or eax, 1 << 8         ; EFER_LME_BIT
    wrmsr

    ; enable paging
    mov eax, cr0
    or eax, 1 << 31        ; CR0_PG_BIT
    mov cr0, eax

    ret


%define PT_P    (1<<0)     ; present
%define PT_RW   (1<<1)     ; writable
%define PT_PS   (1<<7)     ; 2MiB page in PDE
%define ADDRMSK 0xFFFFF000 ; 4K align mask for low dword

init_tables:

    ; PML4[0] = PDPT | P|RW
    mov eax, PDPT
    and eax, ADDRMSK
    or  eax, PT_P | PT_RW
    mov dword [PLM4 + 0], eax
    mov dword [PLM4 + 4], 0

    ; PDPT[0] = PDT | P|RW
    mov eax, PDT
    and eax, ADDRMSK
    or  eax, PT_P | PT_RW
    mov dword [PDPT + 0], eax
    mov dword [PDPT + 4], 0

    ; PDT[0] = 0x000000 (maps 0..2MiB) | P|RW|PS
    mov eax, 0x000000 | PT_P | PT_RW | PT_PS
    mov dword [PDT + 0], eax
    mov dword [PDT + 4], 0

    ret

SECTION .data

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
    .Code.flags: db GRAN_4K | LONG_MODE | 0xF   ; Flags & Limit (high, bits 16-19)
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

SECTION .bss
ALIGN 0x1000
PLM4: resb 0x1000
PDPT: resb 0x1000
PDT:  resb 0x1000
