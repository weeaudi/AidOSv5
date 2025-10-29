BITS 64

SECTION .stage2_header

EXTERN __load
EXTERN _entry
EXTERN __sectors

header:
    db "STG2"
    dd __load
    dd _entry
    dd __sectors

    db "AID3724" ; signature
    db "AIDOS STAGE2 VERSION 0.5" ; version number