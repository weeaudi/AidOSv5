; Minimal prologue/epilogue macros for SysV, 16-byte stack alignment, no red zone
%macro PROLOGUE 0
    ; align stack if needed by caller; save rbp
    push rbp
    mov  rbp, rsp
    ; caller must ensure 16-byte alignment before call;
    ; if you need local space, sub rsp, N (keep 16-byte alignment)
%endmacro

%macro EPILOGUE 0
    mov rsp, rbp
    pop rbp
    ret
%endmacro
