; interpreter_stub.asm - Minimal 64-bit compatible interpreter stub

bits 64

%include "include/kairos.inc"

default rel

section .data
    runtime_error_msg db 'Runtime error', 0
    hello_msg db 'Kairos interpreter is running!', 13, 10, 0

section .text
    global interpreter_init
    global interpreter_run
    global evaluate_node
    global execute_statement
    
    extern printf

interpreter_init:
    ; Initialize interpreter (stub)
    push rbp
    mov rbp, rsp
    
    ; Do nothing for now
    
    mov rsp, rbp
    pop rbp
    ret

interpreter_run:
    ; Run the interpreter with source code (stub)
    ; RCX = pointer to source code
    push rbp
    mov rbp, rsp
    sub rsp, 32         ; Shadow space
    
    ; Just print a hello message for now
    lea rcx, [hello_msg]
    call printf
    
    add rsp, 32
    mov rsp, rbp
    pop rbp
    ret

evaluate_node:
    ; Evaluate AST node (stub)
    ; RCX = AST node
    ; Returns value in RAX
    push rbp
    mov rbp, rsp
    
    ; Return 0 for now
    mov rax, 0
    
    mov rsp, rbp
    pop rbp
    ret

execute_statement:
    ; Execute statement (stub)
    ; RCX = AST node
    push rbp
    mov rbp, rsp
    
    ; Do nothing for now
    
    mov rsp, rbp
    pop rbp
    ret
