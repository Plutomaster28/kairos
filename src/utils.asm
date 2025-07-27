; utils.asm - Utility functions for the Kairos interpreter
; File I/O, memory management, and other helper functions using C runtime

bits 64

%include "include/kairos.inc"

default rel

section .text
    global open_file
    global close_file  
    global read_file
    global print_string
    global kairos_malloc
    global kairos_free
    global string_length
    global string_compare
    global cleanup_all

    extern printf
    extern malloc
    extern free

; Wrapper functions for compatibility
open_file:
    ; This is now handled in main.asm with fopen
    ret

close_file:
    ; This is now handled in main.asm with fclose  
    ret

read_file:
    ; This is now handled in main.asm with fread
    ret

print_string:
    ; Print null-terminated string in RCX using printf (64-bit Windows calling convention)
    push rbp
    mov rbp, rsp
    sub rsp, 32         ; Shadow space
    
    ; RCX already contains the string pointer
    call printf
    
    add rsp, 32
    mov rsp, rbp
    pop rbp
    ret

kairos_malloc:
    ; Wrapper for C malloc (64-bit Windows calling convention)
    ; RCX = size to allocate
    ; Returns pointer in RAX
    push rbp
    mov rbp, rsp
    sub rsp, 32         ; Shadow space
    
    ; RCX already contains the size
    call malloc
    
    add rsp, 32
    mov rsp, rbp
    pop rbp
    ret

kairos_free:
    ; Wrapper for C free (64-bit Windows calling convention)
    ; RCX = pointer to free
    push rbp
    mov rbp, rsp
    sub rsp, 32         ; Shadow space
    
    ; RCX already contains the pointer
    call free
    
    add rsp, 32
    mov rsp, rbp
    pop rbp
    ret

string_length:
    ; Calculate length of null-terminated string (64-bit)
    ; RCX = string pointer
    ; Returns length in RAX
    push rbx
    push rcx
    
    mov rbx, rcx        ; String pointer
    mov rax, 0          ; Counter
    
.loop:
    cmp byte [rbx + rax], 0
    je .done
    inc rax
    jmp .loop
    
.done:
    ; RAX already contains the length
    pop rcx
    pop rbx
    ret

string_compare:
    ; Compare two null-terminated strings (64-bit)
    ; RCX = string1, RDX = string2
    ; Returns 0 if equal, non-zero if different
    push rsi
    push rdi
    
    mov rsi, rcx        ; string1
    mov rdi, rdx        ; string2
    
.loop:
    mov al, [rsi]
    mov bl, [rdi]
    cmp al, bl
    jne .not_equal
    
    test al, al         ; Check if end of string
    jz .equal
    
    inc rsi
    inc rdi
    jmp .loop
    
.equal:
    mov rax, 0
    jmp .done
    
.not_equal:
    mov rax, 1
    
.done:
    pop rdi
    pop rsi
    ret

cleanup_all:
    ; Cleanup all allocated resources
    ret
