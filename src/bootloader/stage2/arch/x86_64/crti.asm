BITS 64

SECTION .init
GLOBAL _init
_init:
    push rbp
    mov rbp, rsp
    ; gcc will put the content of crtbegin.o here

SECTION .fini
GLOBAL _fini
_fini:
    push rbp
    mov rbp, rsp
    ; gcc will put the content of crtend.o here