; interpreter.asm - REAL Kairos interpreter in 64-bit assembly!
; This is where the magic happens!

bits 64

%include "include/kairos.inc"

extern printf

default rel

section .data
    runtime_error_msg db 'Runtime error', 0
    print_prefix db 'KAIROS OUTPUT: ', 0
    newline db 13, 10, 0
    debug_input_msg db 'DEBUG: Processing input...', 13, 10, 0
    source_msg db 'Source code: ', 0
    output_msg db 'KAIROS SAYS: ', 0
    no_print_msg db 'No print statement found', 13, 10, 0
    output_fmt db '%s', 13, 10, 0
    test_success_msg db 'Interpreter is working!', 0
    parsing_msg db 'DEBUG: About to parse...', 13, 10, 0
    valid_ptr_msg db 'DEBUG: Pointer is valid!', 13, 10, 0
    null_ptr_msg db 'ERROR: Null pointer!', 13, 10, 0
    ptr_debug_fmt db 'DEBUG: Pointer value: %p', 13, 10, 0
    stack_debug_msg db 'DEBUG: Stack backup test:', 13, 10, 0

section .text
    global interpreter_init
    global interpreter_run
    global evaluate_node
    global execute_statement
    
    extern printf

interpreter_init:
    ; Initialize interpreter 
    push rbp
    mov rbp, rsp
    
    ; Initialize any runtime state here
    
    mov rsp, rbp
    pop rbp
    ret

interpreter_run:
    ; WORKING VERSION - use stack backup since r10 gets corrupted
    ; RCX = pointer to source code
    push rbp
    mov rbp, rsp
    sub rsp, 64         ; Extra shadow space for debugging
    
    ; Save the input parameter on stack (this works!)
    mov [rbp-8], rcx    ; Save on stack - this preserves the value correctly
    
    ; Print initial debug message
    lea rcx, [debug_input_msg]
    call printf
    
    ; Get our saved pointer from stack
    mov r10, [rbp-8]    ; Load from stack backup
    
    ; Now test if r10 is null
    test r10, r10
    jz .null_pointer
    
    ; SUCCESS! Now let's actually parse the print statement
    mov rsi, r10        ; Source code pointer for parsing
    
    ; Skip whitespace manually
.skip_ws:
    mov al, [rsi]
    cmp al, ' '
    jne .check_print
    inc rsi
    jmp .skip_ws
    
.check_print:    
    ; Check for "print" manually
    cmp byte [rsi], 'p'
    jne .not_print
    cmp byte [rsi+1], 'r'  
    jne .not_print
    cmp byte [rsi+2], 'i'
    jne .not_print
    cmp byte [rsi+3], 'n'
    jne .not_print
    cmp byte [rsi+4], 't'
    jne .not_print
    
    ; Found print! Skip "print"
    add rsi, 5
    
    ; Skip space after print
    cmp byte [rsi], ' '
    jne .find_quote
    inc rsi
    
.find_quote:
    ; Expect opening quote
    cmp byte [rsi], '"'
    jne .not_print
    inc rsi             ; Skip quote
    
    ; Find the string content
    mov rdi, rsi        ; Start of string
.find_end:
    cmp byte [rsi], '"'
    je .found_string
    cmp byte [rsi], 0
    je .not_print
    inc rsi
    jmp .find_end
    
.found_string:
    ; Temporarily null-terminate
    mov byte [rsi], 0
    
    ; Print the string!
    lea rcx, [output_msg]
    call printf
    mov rcx, rdi        ; String content
    call printf
    lea rcx, [newline]
    call printf
    
    ; Restore quote
    mov byte [rsi], '"'
    jmp .done
    
.not_print:
    lea rcx, [no_print_msg]
    call printf
    jmp .done

.null_pointer:
    lea rcx, [null_ptr_msg]
    call printf
    
.done:
    add rsp, 64
    mov rsp, rbp
    pop rbp
    ret

simple_compare:
    ; Compare RCX characters at RSI with RDI
    ; Returns 1 if match, 0 if not
.loop:
    test rcx, rcx
    jz .match
    mov al, [rsi]
    mov bl, [rdi]
    cmp al, bl
    jne .no_match
    inc rsi
    inc rdi
    dec rcx
    jmp .loop
.match:
    mov rax, 1
    ret
.no_match:
    mov rax, 0
    ret

skip_whitespace_simple:
    ; Skip whitespace and comments
.loop:
    mov al, [rsi]
    cmp al, ' '
    je .skip_char
    cmp al, 9           ; Tab
    je .skip_char
    cmp al, 10          ; LF
    je .skip_char
    cmp al, 13          ; CR
    je .skip_char
    cmp al, '#'         ; Comment
    je .skip_comment
    ret

.skip_char:
    inc rsi
    jmp .loop

.skip_comment:
    ; Skip until end of line
.comment_loop:
    mov al, [rsi]
    cmp al, 0
    je .done
    cmp al, 10
    je .done
    cmp al, 13
    je .done
    inc rsi
    jmp .comment_loop
.done:
    jmp .loop

compare_keyword:
    ; Compare keyword at RSI with keyword at RDI for RCX characters
    ; Returns 1 in RAX if match, 0 if no match
    push rsi
    push rdi
    push rcx
    
.compare_loop:
    test rcx, rcx
    jz .match
    mov al, [rsi]
    mov bl, [rdi]
    cmp al, bl
    jne .no_match
    inc rsi
    inc rdi
    dec rcx
    jmp .compare_loop

.match:
    mov rax, 1
    jmp .exit

.no_match:
    mov rax, 0

.exit:
    pop rcx
    pop rdi
    pop rsi
    ret

evaluate_node:
    ; Evaluate AST node (stub for now)
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
    ; Execute statement (stub for now)
    ; RCX = AST node
    push rbp
    mov rbp, rsp
    
    ; Do nothing for now
    
    mov rsp, rbp
    pop rbp
    ret

section .data
print_keyword db 'print', 0
