; memory_stub.asm - Minimal 64-bit compatible memory management stub

bits 64

%include "include/kairos.inc"

default rel

section .data
    heap_initialized db 0

section .text
    global heap_init
    global kairos_malloc
    global kairos_free
    global garbage_collect
    
    extern malloc
    extern free

heap_init:
    ; Initialize heap (stub)
    push rbp
    mov rbp, rsp
    
    mov byte [heap_initialized], 1
    
    mov rsp, rbp
    pop rbp
    ret

kairos_malloc:
    ; Wrapper for malloc (64-bit compatible)
    ; RCX = size
    ; Returns pointer in RAX
    push rbp
    mov rbp, rsp
    sub rsp, 32         ; Shadow space
    
    ; RCX already contains size
    call malloc
    
    add rsp, 32
    mov rsp, rbp
    pop rbp
    ret

kairos_free:
    ; Wrapper for free (64-bit compatible)
    ; RCX = pointer
    push rbp
    mov rbp, rsp
    sub rsp, 32         ; Shadow space
    
    ; RCX already contains pointer
    call free
    
    add rsp, 32
    mov rsp, rbp
    pop rbp
    ret

garbage_collect:
    ; Garbage collection (stub)
    push rbp
    mov rbp, rsp
    
    ; Do nothing for now
    
    mov rsp, rbp
    pop rbp
    ret
