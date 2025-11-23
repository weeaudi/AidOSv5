; ------------------------------------------------------------------
; AIDOS Stage2 data grab — Get data from bios
; ------------------------------------------------------------------

BITS 16

%define MAX_ENTRIES 20

GLOBAL grab_memory
GLOBAL find_rsdp
GLOBAL pci_bios_install_check

GLOBAL pci_sig
GLOBAL pci_pm_entry
GLOBAL pci_hwchr
GLOBAL pci_lastbus
GLOBAL pci_ver

EXTERN memory_map

SECTION .text

grab_memory:
    xor bx, bx                  ; EBX=0 to start
    mov di, memory_map          ; offset into memory_map
    push ds
.next:
    mov ax, 0
    mov es, ax                  ; ES:DI -> buffer for one entry
    ; set up request
    mov eax, 0xE820
    mov edx, 0x534D4150         ; 'SMAP'
    mov ecx, 20                 ; request 20-byte entry
    int 0x15
    jc .done                    ; carry => error or done
    cmp eax, 0x534D4150
    jne .done
    ; On return: ECX=size (>=20), ES:DI filled, EBX=continuation
    add di, 20                  ; next slot
    cmp di, (MAX_ENTRIES*20) + memory_map
    jae .done
    test ebx, ebx               ; EBX==0 => no more
    jnz .next
.done:
    pop ds
    ret

find_rsdp:
    push ax
    push bx
    push cx
    push dx
    push si

    mov ax, 0x40
    mov es, ax
    mov bx, [es:0x0E]
    test bx, bx
    jz .scan_high
    mov es, bx
    xor di, di
    mov cx, 1024/16
    call .scan_block
    jnc .found

.scan_high:
    mov ax, 0xE000
    mov es, ax
    xor di, di
    mov cx, (0x10000/16)
    call .scan_block
    jnc .found

    mov ax, 0xF000
    mov es, ax
    xor di, di
    mov cx, (0x10000/16)
    call .scan_block
    jnc .found

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    stc
    ret

.found:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    clc
    ret

.scan_block:
.next:
    push cx
    mov si, rsdp_sig
    mov bx, 8
.cmp:
    mov al, [es:di]
    cmp al, [si]
    jne .no
    inc di
    inc si
    dec bx
    jnz .cmp
    pop cx
    sub di, 8
    mov cx, 20
    xor al, al
    xor si, si
.sum1:
    mov bx, di
    add al, [es:bx+si]
    inc si
    loop .sum1
    test al, al
    jnz .no
    mov al, [es:di+15]
    cmp al, 2
    jb .found2
    mov bx, [es:di+20]
    cmp bx, 20
    jb .found2
    xor si, si
    xor al, al
    mov cx, bx
.sum2:
    mov bx, di
    add al, [es:bx+si]
    inc si
    loop .sum2
    test al, al
    jnz .no
.found2:
    clc
    ret
.no:
    pop cx
    add bx, 8
    add di, bx
    loop .next
    stc
    ret

pci_bios_install_check:
    pusha
    xor    edi, edi          ; EDI must be 0
    mov    ax, 0xB101
    int    0x1A
    jc     .fail             ; CF set -> not present / error
    cmp    ah, 0
    jne    .fail

    ; Save outputs
    mov    [pci_sig],    edx ; 'PCI ' = 0x20494350
    mov    [pci_hwchr],  al  ; hardware characteristics bitfield
    mov    [pci_ver],    bx  ; BCD: BH=major, BL=minor
    mov    [pci_lastbus],cl  ; last PCI bus number
    mov    [pci_pm_entry],edi ; phys addr of PM entry

    clc
    jmp    .out
.fail:
    stc
.out:
    popa
    ret

SECTION .data16

pci_sig:       dd 0          ; expected 0x20494350 ('PCI ')
pci_pm_entry:  dd 0          ; protected-mode entry point (physical)
pci_hwchr:     db 0          ; bit0=mech1, bit1=mech2, bit4/5=special cycle mechs
pci_lastbus:   db 0
pci_ver:       dw 0          ; BH:BL = BCD version (e.g., 0x0201 = 2.01)

rsdp_sig: db 'RSD PTR '        ; 8 bytes with trailing space.