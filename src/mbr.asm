; nasm -f bin mbr.asm -o mbr.bin
BITS 16
ORG 0x7C00

start:
    cli
    xor ax,ax
    mov ss,ax
    mov sp,0x7C00
    mov ds,ax
    mov es,ax
    sti
    mov [BootDL], dl

    ; relocate 512 bytes: 7C00 -> 0600 (forward, no overlap issue)
    cld
    mov si,0x7C00
    mov di,0x0600
    mov cx,512
    rep movsb
    jmp 0:reloc-(0x7C00-0x600)                  ; continue in relocated copy

; ===== runs at 0000:0621 =====
reloc:
    ; find active partition at 0x07BE
    mov si,0x07BE
    mov cx,4
.find:
    cmp byte [si],0x80
    je  .got
    add si,16
    loop .find
    ; fallback: first nonzero type
    mov si,0x07BE
    mov cx,4
.fall:
    cmp byte [si+4],0
    jne .got
    add si,16
    loop .halt

.got:
    ; optional reset
    mov dl,[BootDL]
    xor ah,ah
    int 0x13

    ; DAP at 0500, read 1 sector from entry LBA -> 0000:7C00
    mov bx,0x0500
    mov byte  [bx],0x10
    mov byte  [bx+1],0
    mov word  [bx+2],1
    mov word  [bx+4],0x7C00
    mov word  [bx+6],0x0000
    mov dword eax, [si+8]
    mov dword [bx+8], eax
    mov dword [bx+12],0

    xor ax, ax

    mov si,bx
    mov dl,[BootDL]
    mov ah,0x42                  ; INT 13h extensions
    int 0x13
    jc  .retry
    jmp 0:0x7C00

.retry:
    mov dl,[BootDL]
    xor ah,ah
    int 0x13
    mov si,bx
    mov dl,[BootDL]
    mov ah,0x42
    int 0x13
    jc  .halt
    jmp 0:0x7C00

.halt:
    jmp .halt

BootDL db 0
