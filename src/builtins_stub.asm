; builtins_stub.asm - Minimal 64-bit compatible builtins stub 

bits 64

%include "include/kairos.inc"

default rel

section .data
    hello_builtin_msg db 'Built-in functions loaded', 13, 10, 0

section .text
    global builtin_print
    global builtin_input
    global builtin_str
    global builtin_num
    global builtin_len
    global init_builtins
    
    extern printf

init_builtins:
    ; Initialize built-in functions (stub)
    push rbp
    mov rbp, rsp
    
    ; Do nothing for now
    
    mov rsp, rbp
    pop rbp
    ret

builtin_print:
    ; Print function (stub)
    ; RCX = value to print
    push rbp
    mov rbp, rsp
    sub rsp, 32         ; Shadow space
    
    ; Just print a message for now
    lea rcx, [hello_builtin_msg]
    call printf
    
    add rsp, 32
    mov rsp, rbp
    pop rbp
    ret

builtin_input:
    ; Input function (stub)
    ; Returns string in RAX
    push rbp
    mov rbp, rsp
    
    ; Return NULL for now
    mov rax, 0
    
    mov rsp, rbp
    pop rbp
    ret

builtin_str:
    ; String conversion (stub)
    ; RCX = value
    ; Returns string in RAX
    push rbp
    mov rbp, rsp
    
    ; Return NULL for now
    mov rax, 0
    
    mov rsp, rbp
    pop rbp
    ret

builtin_num:
    ; Number conversion (stub)
    ; RCX = string
    ; Returns number in RAX
    push rbp
    mov rbp, rsp
    
    ; Return 0 for now
    mov rax, 0
    
    mov rsp, rbp
    pop rbp
    ret

builtin_len:
    ; Length function (stub)
    ; RCX = value
    ; Returns length in RAX
    push rbp
    mov rbp, rsp
    
    ; Return 0 for now
    mov rax, 0
    
    mov rsp, rbp
    pop rbp
    ret
