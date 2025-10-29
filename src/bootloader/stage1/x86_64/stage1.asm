; ------------------------------------------------------------------
; AIDOS Stage1 (PBR) — discover partition via MBR, find header at
; (part_base + 1), load stage2 from (part_base + 2) and jump.
; Header layout (at LBA part+1):
;   00:  "STG2"        (4)
;   04:  __load        (u32 linear address)
;   08:  _entry        (u32 linear address)
;   0C:  __sectors     (u32 count)
;   10:  "AID3724"     (7)
; ------------------------------------------------------------------

BITS 16

%define MBR_PART_TABLE     0x1BE
%define PART_ENTRY_SIZE    16
%define PART_TYPE_OFF      4
%define PART_LBA_OFF       8
%define MBR_SIG_OFF        510
%define MBR_SIG            0xAA55

%define HDR_MAGIC_OFF      0x00
%define HDR_LOAD_OFF       0x04
%define HDR_ENTRY_OFF      0x08
%define HDR_SECTORS_OFF    0x0C
%define HDR_SIG_OFF        0x10           ; signature "AID3724" lives here
%define MAX_CHUNK_SECTORS  127

GLOBAL _start

SECTION .text
_start:
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    mov [boot_drive], dl

    ; ---- Read MBR (LBA 0) -> mbr_buf ----
    xor eax, eax                      ; LBA 0
    mov bx, mbr_buf
    mov cx, 1
    mov dl, [boot_drive]
    call disk_read
    jc  fail

    ; verify MBR signature
    mov si, mbr_buf
    cmp word [si + MBR_SIG_OFF], MBR_SIG
    jne fail

    ; ---- Iterate 4 partition entries ----
    mov di, MBR_PART_TABLE
    mov bp, 4

next_entry:
    mov al, [mbr_buf + di + PART_TYPE_OFF]
    test al, al
    jz  skip

    ; part_base_lba = dword at entry+8
    mov eax, dword [mbr_buf + di + PART_LBA_OFF]
    mov [part_base_lba], eax

    ; read header sector (part + 1) -> hdr_buf
    mov eax, [part_base_lba]
    add eax, 1
    mov bx, hdr_buf
    mov cx, 1
    mov dl, [boot_drive]
    call disk_read
    jc  skip

    ; check signature "AID3724" at 0x10
    mov si, hdr_buf + HDR_SIG_OFF
    mov bx, sig_str
    call memcmp7
    jnc skip

    ; check magic "STG2" at 0x00
    mov si, hdr_buf + HDR_MAGIC_OFF
    mov bx, magic_str
    call memcmp4
    jnc skip

    ; ---- Header OK: pull params ----
    mov eax, dword [hdr_buf + HDR_LOAD_OFF]
    mov [dst_linear], eax
    mov eax, dword [hdr_buf + HDR_ENTRY_OFF]
    mov [entry_linear], eax
    mov eax, dword [hdr_buf + HDR_SECTORS_OFF]
    mov [remaining_sectors], eax

    ; start reading at (part + 2)
    mov eax, [part_base_lba]
    add eax, 2
    mov [cur_lba], eax

load_loop:
    mov eax, [remaining_sectors]
    test eax, eax
    jz  jump_entry

    ; chunk = min(remaining, MAX_CHUNK_SECTORS)
    mov ecx, eax
    cmp ecx, MAX_CHUNK_SECTORS
    jbe .have_chunk
    mov ecx, MAX_CHUNK_SECTORS
.have_chunk:
    mov [chunk_count], cx

    ; ES:BX = dst_linear
    mov eax, [dst_linear]
    call linear_to_esbx

    ; read chunk sectors
    mov eax, [cur_lba]
    mov cx, [chunk_count]
    mov dl, [boot_drive]
    call disk_read
    jc  fail

    ; advance LBA
    movzx eax, word [chunk_count]
    add [cur_lba], eax

    ; advance dst_linear by chunk*512
    mov edx, eax
    shl edx, 9
    add [dst_linear], edx

    ; remaining -= chunk
    mov eax, [remaining_sectors]
    mov ecx, [chunk_count]
    sub eax, ecx
    mov [remaining_sectors], eax
    jmp load_loop

jump_entry:
    mov eax, [entry_linear]
    mov dl, [boot_drive]
    jmp dword eax

skip:
    add di, PART_ENTRY_SIZE
    dec bp
    jnz next_entry

fail:
    cli
.hang:
    hlt
    jmp .hang

; ---------------- helpers ----------------

; disk_read: EAX=LBA, ES:BX=buf, CX=count, DL=drive
disk_read:
    push si
    push es
    push bx
    push cx
    push dx

    mov si, dap
    mov byte  [si+0],  0x10
    mov byte  [si+1],  0
    mov word  [si+2],  cx
    mov word  [si+4],  bx
    mov word  [si+6],  es
    mov dword [si+8],  eax
    mov dword [si+12], 0

    mov ah, 0x42
    int 0x13                         ; CF set on error

    pop dx
    pop cx
    pop bx
    pop es
    pop si
    ret

; linear_to_esbx: EAX=linear -> ES:BX
linear_to_esbx:
    push dx
    mov edx, eax
    and ax, 0x000F
    mov bx, ax
    mov ax, dx
    shr eax, 4
    mov es, ax
    pop dx
    ret

; memcmp4: DS:SI compared to DS:BX, 4 bytes, returns CF=1 if equal
memcmp4:
    push cx
    mov cx, 4
.m4:
    mov al, [si]
    cmp al, [bx]
    jne .m4_ne
    inc si
    inc bx
    loop .m4
    pop cx
    stc
    ret
.m4_ne:
    pop cx
    clc
    ret

; memcmp7: DS:SI compared to DS:BX, 7 bytes, returns CF=1 if equal
memcmp7:
    push cx
    mov cx, 7
.m7:
    mov al, [si]
    cmp al, [bx]
    jne .m7_ne
    inc si
    inc bx
    loop .m7
    pop cx
    stc
    ret
.m7_ne:
    pop cx
    clc
    ret

SECTION .data
boot_drive:         db 0
sig_str:            db "AID3724"
magic_str:          db "STG2"

SECTION .bss

mbr_buf: resb 512
hdr_buf: resb 512

dap:                times 16 resb 1

part_base_lba:      resd 1
cur_lba:            resd 1
remaining_sectors:  resd 1
chunk_count:        resd 1
dst_linear:         resd 1
entry_linear:       resd 1
