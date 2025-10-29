; ------------------------------------------------------------------
; AIDOS Stage2 Entry — Get data from bios then switch to long mode and call C Init
; ------------------------------------------------------------------

BITS 16

GLOBAL _entry
GLOBAL memory_map

EXTERN __top
EXTERN __bss_start
EXTERN __bss_size

EXTERN grab_memory
EXTERN find_rsdp

SECTION .text16 progbits alloc exec nowrite

_entry:
    mov sp, __top

    mov [boot_drive], dl

    call clear_bss

    call grab_memory

    call find_rsdp

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

SECTION .data16 write
boot_drive: db 0
; we need this in the lower section of memory
; so we keep it in data16 rather than bss
memory_map: times 400 db 0