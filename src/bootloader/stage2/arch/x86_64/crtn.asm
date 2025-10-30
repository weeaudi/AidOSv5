BITS 64

SECTION .init
    ; gcc will put the content of crtbegin.o here
    pop rbp
    ret

SECTION .fini
    ; gcc will put the content of crtend.o here
    pop rbp
    ret