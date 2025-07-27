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
    
    ; Check command line arguments
    cmp r14, 2
    jl .show_usage
    
    ; Get filename from argv[1]
    mov rax, r15        ; argv
    add rax, 8          ; Point to argv[1] (8 bytes per pointer in 64-bit)
    mov rbx, [rax]      ; Get argv[1]
    mov [filename], rbx
    
    ; Initialize interpreter components
    call lexer_init
    call parser_init
    call interpreter_init
    
    ; Open source file
    mov rcx, [filename]  ; filename
    lea rdx, [read_mode] ; mode
    call fopen
    test rax, rax
    jz .file_error
    mov [file_handle], rax
    
    ; Get file size
    mov rcx, [file_handle]
    mov rdx, 0          ; offset
    mov r8, 2           ; SEEK_END
    call fseek
    
    mov rcx, [file_handle]
    call ftell
    mov [file_size], rax
    
    ; Reset to beginning
    mov rcx, [file_handle]
    mov rdx, 0          ; offset
    mov r8, 0           ; SEEK_SET
    call fseek
    
    ; Allocate memory for source code
    mov rcx, [file_size]
    add rcx, 1          ; +1 for null terminator
    call malloc
    test rax, rax
    jz .memory_error
    mov [source_code], rax
    
    ; Read file contents
    mov rcx, [source_code]  ; buffer
    mov rdx, 1              ; size
    mov r8, [file_size]     ; count
    mov r9, [file_handle]   ; file
    call fread
    
    ; Null terminate the source code
    mov rax, [source_code]
    mov rbx, [file_size]
    add rax, rbx
    mov cl, 0
    mov [rax], cl
    
    ; Close file
    mov rcx, [file_handle]
    call fclose
    add esp, 4
    
    ; Run the interpreter
    mov rcx, [source_code]
    call interpreter_run
    
    ; Cleanup and exit
    call cleanup_all
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
