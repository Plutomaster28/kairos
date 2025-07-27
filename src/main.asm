; main.asm - Entry point for the Kairos interpreter
; Written in x86-64 Assembly for Windows

bits 64

%include "include/kairos.inc"

default rel

section .data
    banner db 'Kairos Programming Language Interpreter v0.1', 13, 10, 0
    usage_msg db 'Usage: kairos <script.kr>', 13, 10, 0
    file_error db 'Error: Could not open file', 13, 10, 0
    memory_error_msg db 'Error: Out of memory', 13, 10, 0
    read_mode db 'rb', 0
    test_program db 'print "Hello, World!"', 0
    debug_test_msg db 'DEBUG: test_program contents: ', 0
    newline_msg db 13, 10, 0
    addr_debug_msg db 'DEBUG: About to call interpreter...', 13, 10, 0
    
section .bss
    filename resq 1
    file_handle resq 1
    file_size resq 1
    source_code resq 1

section .text
    global main
    
    extern printf
    extern fopen
    extern fclose
    extern fread
    extern fseek
    extern ftell
    extern malloc
    extern free
    extern lexer_init
    extern parser_init
    extern interpreter_init
    extern interpreter_run
    extern cleanup_all

main:
    ; Windows x64 calling convention: RCX, RDX, R8, R9, then stack
    push rbp
    mov rbp, rsp
    sub rsp, 48         ; Shadow space + alignment + local vars
    
    ; Save argc and argv in registers (simpler approach)
    mov r14, rcx        ; argc  
    mov r15, rdx        ; argv
    
    ; Print banner
    lea rcx, [banner]
    call printf
    
    ; DEBUG: Test if we can access test_program in main
    lea rcx, [debug_test_msg]
    call printf
    
    ; Try to print the test_program directly from main
    lea rcx, [test_program]
    call printf
    
    lea rcx, [newline_msg]
    call printf
    
    ; ALWAYS use test program for now (bypass file handling)
    ; Initialize interpreter components
    ; call lexer_init
    ; call parser_init
    ; call interpreter_init
    
    ; DEBUG: Print address of test_program before call
    lea rcx, [addr_debug_msg]
    call printf
    
    ; Save test_program address in a safe register
    lea r12, [test_program]
    
    ; Test interpreter directly with hardcoded string
    mov rcx, r12        ; Move address from r12 to rcx
    call interpreter_run
    
    ; Cleanup and exit
    ; call cleanup_all
    mov rax, 0          ; Exit code 0
    jmp exit

.show_usage:
    lea rcx, [usage_msg]
    call printf
    mov rax, 1          ; Exit code 1
    jmp exit

.file_error:
    lea rcx, [file_error]  
    call printf
    mov rax, 2          ; Exit code 2
    jmp exit

.memory_error:
    lea rcx, [memory_error_msg]
    call printf
    mov rax, 3          ; Exit code 3
    jmp exit

exit:
    ; Standard C return (64-bit)
    mov rsp, rbp
    pop rbp
    ret
