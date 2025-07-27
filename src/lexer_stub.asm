; lexer_stub.asm - Minimal 64-bit compatible lexer stub
; This is a temporary stub to get the project building

bits 64

%include "include/kairos.inc"

default rel

section .data
    ; Keyword strings
    kw_if_str db 'if', 0
    kw_else_str db 'else', 0
    kw_while_str db 'while', 0
    kw_for_str db 'for', 0
    kw_function_str db 'function', 0
    kw_return_str db 'return', 0
    kw_local_str db 'local', 0
    kw_global_str db 'global', 0
    kw_print_str db 'print', 0
    kw_input_str db 'input', 0
    
    ; Keywords table (64-bit pointers)
    keywords:
        dq kw_if_str, KW_IF
        dq kw_else_str, KW_ELSE
        dq kw_while_str, KW_WHILE
        dq kw_for_str, KW_FOR
        dq kw_function_str, KW_FUNCTION
        dq kw_return_str, KW_RETURN
        dq kw_local_str, KW_LOCAL
        dq kw_global_str, KW_GLOBAL
        dq kw_print_str, KW_PRINT
        dq kw_input_str, KW_INPUT
        dq 0, 0             ; End marker

section .bss
    current_pos resq 1      ; Current position in source code (64-bit)
    current_line resq 1     ; Current line number
    current_column resq 1   ; Current column number
    source_start resq 1     ; Start of source code (64-bit pointer)
    source_end resq 1       ; End of source code (64-bit pointer)
    token_buffer resb 256   ; Buffer for current token

section .text
    global lexer_init
    global next_token
    global peek_token
    global is_keyword
    global is_operator
    global skip_whitespace
    
    extern malloc
    extern string_compare
    extern string_length

lexer_init:
    ; Initialize lexer with source code (64-bit stub)
    ; RCX = pointer to source code
    push rbp
    mov rbp, rsp
    
    mov [source_start], rcx
    mov [current_pos], rcx
    mov qword [current_line], 1
    mov qword [current_column], 1
    
    ; Calculate source end (simplified)
    mov rax, rcx
    add rax, 1000       ; Assume max 1000 chars for now
    mov [source_end], rax
    
    mov rsp, rbp
    pop rbp
    ret

next_token:
    ; Get next token from source code (stub)
    ; Returns pointer to Token structure in RAX
    push rbp
    mov rbp, rsp
    
    ; Return NULL for now (stub)
    mov rax, 0
    
    mov rsp, rbp
    pop rbp
    ret

peek_token:
    ; Peek at next token without consuming it (stub)
    push rbp
    mov rbp, rsp
    
    ; Return NULL for now (stub)
    mov rax, 0
    
    mov rsp, rbp
    pop rbp
    ret

is_keyword:
    ; Check if string in RCX is a keyword (stub)
    ; Returns keyword ID in RAX, or 0 if not a keyword
    push rbp
    mov rbp, rsp
    
    ; Return 0 for now (stub)
    mov rax, 0
    
    mov rsp, rbp
    pop rbp
    ret

is_operator:
    ; Check if character in CL is an operator (stub)
    ; Returns 1 if operator, 0 if not
    push rbp
    mov rbp, rsp
    
    ; Return 0 for now (stub)
    mov rax, 0
    
    mov rsp, rbp
    pop rbp
    ret

skip_whitespace:
    ; Skip whitespace and comments (stub)
    push rbp
    mov rbp, rsp
    
    ; Do nothing for now (stub)
    
    mov rsp, rbp
    pop rbp
    ret
