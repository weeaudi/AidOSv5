; ------------------------------------------------------------------
; AIDOS Stage2 Entry — Get data from bios then switch to long mode and call C Init
; ------------------------------------------------------------------

BITS 16

GLOBAL _entry
GLOBAL memory_map
GLOBAL rsdp

EXTERN __top
EXTERN __bss_start
EXTERN __bss_size

EXTERN grab_memory
EXTERN find_rsdp
EXTERN pci_bios_install_check
EXTERN init_32
EXTERN init_64
EXTERN _init
EXTERN aidos_stage2_main

SECTION .text

_entry:
    mov sp, __top

    mov [boot_drive], dl

    call clear_bss

    call grab_memory

    call find_rsdp

    call pci_bios_install_check

    push es
    push di
    pop dword [rsdp]

    push start_32
    jmp init_32

.loop:
    jmp .loop

clear_bss:
    ; Ensure ES = DS because STOS uses ES:DI
    push ds
    pop  es

    cld                     ; forward direction
    xor ax, ax              ; value to store (0)

    mov edi, __bss_start     ; destination offset
    mov ecx, __bss_size
    jcxz .done

    rep stosb               ; byte clear [ES:DI] for CX bytes
.done:
    ret

.loop:
    jmp .loop
    ret

BITS 32

start_32:

    push start_64
    jmp init_64

    cli
    hlt
    jmp start_32

BITS 64

start_64:

    call _init
    call aidos_stage2_main

    cli
    hlt

SECTION .data16
boot_drive: db 0
; we need this in the lower section of memory
; so we keep it in data16 rather than bss
memory_map: times 400 db 0
rsdp: dw 0