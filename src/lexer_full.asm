; lexer.asm - Tokenizer for the Kairos programming language
; Breaks source code into tokens for parsing

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
    ; Initialize lexer with source code
    ; EAX = pointer to source code
    push ebx
    push ecx
    
    mov [source_start], eax
    mov [current_pos], eax
    mov dword [current_line], 1
    mov dword [current_column], 1
    
    ; Calculate source end
    mov ebx, eax
    call string_length
    add eax, ebx
    mov [source_end], eax
    
    pop ecx
    pop ebx
    ret

next_token:
    ; Get next token from source code
    ; Returns pointer to Token structure in EAX
    ; Returns NULL if EOF
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    
    call skip_whitespace
    
    ; Check for EOF
    mov eax, [current_pos]
    cmp eax, [source_end]
    jge .eof
    
    ; Allocate token structure
    mov eax, Token_size
    call malloc
    test eax, eax
    jz .eof
    mov edi, eax        ; Save token pointer
    
    ; Set line and column
    mov eax, [current_line]
    mov [edi + Token.line], eax
    mov eax, [current_column]
    mov [edi + Token.column], eax
    
    ; Get current character
    mov esi, [current_pos]
    mov al, [esi]
    
    ; Check character type
    cmp al, '"'
    je .string_literal
    cmp al, "'"
    je .string_literal
    
    ; Check if digit
    cmp al, '0'
    jb .not_digit
    cmp al, '9'
    ja .not_digit
    jmp .number
    
.not_digit:
    ; Check if letter or underscore (identifier start)
    cmp al, 'a'
    jb .not_alpha_lower
    cmp al, 'z'
    jbe .identifier
.not_alpha_lower:
    cmp al, 'A'
    jb .not_alpha_upper
    cmp al, 'Z'
    jbe .identifier
.not_alpha_upper:
    cmp al, '_'
    je .identifier
    
    ; Check operators and delimiters
    jmp .operator_or_delimiter

.string_literal:
    call parse_string
    mov [edi + Token.type], dword TOKEN_STRING
    jmp .done

.number:
    call parse_number
    mov [edi + Token.type], dword TOKEN_NUMBER
    jmp .done

.identifier:
    call parse_identifier
    ; Check if it's a keyword
    mov eax, token_buffer
    call is_keyword
    test eax, eax
    jz .regular_identifier
    
    mov [edi + Token.type], dword TOKEN_KEYWORD
    mov [edi + Token.value], eax
    jmp .done
    
.regular_identifier:
    mov [edi + Token.type], dword TOKEN_IDENTIFIER
    jmp .done

.operator_or_delimiter:
    call parse_operator
    test eax, eax
    jz .delimiter
    
    mov [edi + Token.type], dword TOKEN_OPERATOR
    jmp .done

.delimiter:
    call parse_delimiter
    mov [edi + Token.type], dword TOKEN_DELIMITER
    jmp .done

.done:
    ; Set token value if not already set
    cmp dword [edi + Token.value], 0
    jne .return_token
    
    ; Copy token buffer to allocated string
    mov eax, token_buffer
    call string_length
    inc eax             ; +1 for null terminator
    call malloc
    test eax, eax
    jz .error
    
    mov [edi + Token.value], eax
    ; Copy string
    mov esi, token_buffer
    mov ecx, 256        ; Max copy
    rep movsb

.return_token:
    mov eax, edi        ; Return token pointer
    jmp .exit

.eof:
    mov eax, 0          ; Return NULL for EOF
    jmp .exit

.error:
    mov eax, 0          ; Return NULL on error
    
.exit:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

parse_string:
    ; Parse string literal starting at current position
    push ebx
    push ecx
    push esi
    push edi
    
    mov esi, [current_pos]
    mov edi, token_buffer
    mov bl, [esi]       ; Quote character (' or ")
    inc esi             ; Skip opening quote
    inc dword [current_column]
    
.loop:
    mov al, [esi]
    test al, al         ; Check for end of source
    jz .error
    
    cmp al, bl          ; Check for closing quote
    je .done
    
    cmp al, '\'         ; Check for escape character
    je .escape
    
    ; Regular character
    mov [edi], al
    inc esi
    inc edi
    inc dword [current_column]
    jmp .loop

.escape:
    inc esi             ; Skip backslash
    inc dword [current_column]
    mov al, [esi]
    
    ; Handle escape sequences
    cmp al, 'n'
    je .newline_escape
    cmp al, 't'
    je .tab_escape
    cmp al, 'r'
    je .return_escape
    cmp al, '\'
    je .backslash_escape
    
    ; Default: just copy the character
    mov [edi], al
    jmp .continue_escape

.newline_escape:
    mov al, 10          ; \n
    mov [edi], al
    jmp .continue_escape

.tab_escape:
    mov al, 9           ; \t
    mov [edi], al
    jmp .continue_escape

.return_escape:
    mov al, 13          ; \r
    mov [edi], al
    jmp .continue_escape

.backslash_escape:
    mov al, '\'         ; \\
    mov [edi], al

.continue_escape:
    inc esi
    inc edi
    inc dword [current_column]
    jmp .loop

.done:
    inc esi             ; Skip closing quote
    inc dword [current_column]
    mov byte [edi], 0   ; Null terminate
    mov [current_pos], esi
    jmp .exit

.error:
    ; TODO: Set error flag
    
.exit:
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret

parse_number:
    ; Parse numeric literal
    push esi
    push edi
    push ecx
    
    mov esi, [current_pos]
    mov edi, token_buffer
    mov ecx, 0          ; Character count
    
.loop:
    mov al, [esi]
    
    ; Check if digit
    cmp al, '0'
    jb .check_dot
    cmp al, '9'
    ja .check_dot
    
    ; It's a digit
    mov [edi], al
    inc esi
    inc edi
    inc ecx
    inc dword [current_column]
    jmp .loop

.check_dot:
    cmp al, '.'
    jne .done
    
    ; It's a decimal point
    mov [edi], al
    inc esi
    inc edi
    inc ecx
    inc dword [current_column]
    jmp .loop

.done:
    mov byte [edi], 0   ; Null terminate
    mov [current_pos], esi
    
    pop ecx
    pop edi
    pop esi
    ret

parse_identifier:
    ; Parse identifier (variable name, function name, etc.)
    push esi
    push edi
    push ecx
    
    mov esi, [current_pos]
    mov edi, token_buffer
    mov ecx, 0
    
.loop:
    mov al, [esi]
    
    ; Check if alphanumeric or underscore
    cmp al, 'a'
    jb .check_upper
    cmp al, 'z'
    jbe .valid_char
    
.check_upper:
    cmp al, 'A'
    jb .check_digit
    cmp al, 'Z'
    jbe .valid_char
    
.check_digit:
    cmp al, '0'
    jb .check_underscore
    cmp al, '9'
    jbe .valid_char
    
.check_underscore:
    cmp al, '_'
    jne .done
    
.valid_char:
    mov [edi], al
    inc esi
    inc edi
    inc ecx
    inc dword [current_column]
    jmp .loop

.done:
    mov byte [edi], 0   ; Null terminate
    mov [current_pos], esi
    
    pop ecx
    pop edi
    pop esi
    ret

parse_operator:
    ; Parse operator
    ; Returns operator type in EAX, or 0 if not an operator
    push esi
    push edi
    
    mov esi, [current_pos]
    mov edi, token_buffer
    mov al, [esi]
    
    ; Single character operators
    cmp al, '+'
    je .single_char
    cmp al, '-'
    je .single_char
    cmp al, '*'
    je .single_char
    cmp al, '/'
    je .single_char
    cmp al, '%'
    je .single_char
    cmp al, '='
    je .check_double_equal
    cmp al, '!'
    je .check_not_equal
    cmp al, '<'
    je .check_less_equal
    cmp al, '>'
    je .check_greater_equal
    cmp al, '&'
    je .check_logical_and
    cmp al, '|'
    je .check_logical_or
    
    ; Not an operator
    mov eax, 0
    jmp .exit

.single_char:
    mov [edi], al
    mov byte [edi + 1], 0
    inc esi
    inc dword [current_column]
    mov [current_pos], esi
    mov eax, 1          ; Found operator
    jmp .exit

.check_double_equal:
    cmp byte [esi + 1], '='
    jne .single_char
    
    ; It's ==
    mov [edi], al
    mov byte [edi + 1], '='
    mov byte [edi + 2], 0
    add esi, 2
    add dword [current_column], 2
    mov [current_pos], esi
    mov eax, 1
    jmp .exit

.check_not_equal:
    cmp byte [esi + 1], '='
    jne .single_char
    
    ; It's !=
    mov [edi], al
    mov byte [edi + 1], '='
    mov byte [edi + 2], 0
    add esi, 2
    add dword [current_column], 2
    mov [current_pos], esi
    mov eax, 1
    jmp .exit

.check_less_equal:
    cmp byte [esi + 1], '='
    je .double_char
    jmp .single_char

.check_greater_equal:
    cmp byte [esi + 1], '='
    je .double_char
    jmp .single_char

.check_logical_and:
    cmp byte [esi + 1], '&'
    je .double_char
    mov eax, 0          ; Single & is not a valid operator
    jmp .exit

.check_logical_or:
    cmp byte [esi + 1], '|'
    je .double_char
    mov eax, 0          ; Single | is not a valid operator
    jmp .exit

.double_char:
    mov [edi], al
    mov bl, [esi + 1]
    mov [edi + 1], bl
    mov byte [edi + 2], 0
    add esi, 2
    add dword [current_column], 2
    mov [current_pos], esi
    mov eax, 1
    jmp .exit

.exit:
    pop edi
    pop esi
    ret

parse_delimiter:
    ; Parse delimiter (parentheses, brackets, etc.)
    push esi
    push edi
    
    mov esi, [current_pos]
    mov edi, token_buffer
    mov al, [esi]
    
    ; Check for valid delimiters
    cmp al, '('
    je .valid_delimiter
    cmp al, ')'
    je .valid_delimiter
    cmp al, '{'
    je .valid_delimiter
    cmp al, '}'
    je .valid_delimiter
    cmp al, '['
    je .valid_delimiter
    cmp al, ']'
    je .valid_delimiter
    cmp al, ','
    je .valid_delimiter
    cmp al, ';'
    je .valid_delimiter
    cmp al, ':'
    je .valid_delimiter
    
    jmp .not_delimiter

.valid_delimiter:
    mov [edi], al
    mov byte [edi + 1], 0
    inc esi
    inc dword [current_column]
    mov [current_pos], esi
    jmp .exit

.not_delimiter:
    ; Skip unknown character
    inc esi
    inc dword [current_column]
    mov [current_pos], esi

.exit:
    pop edi
    pop esi
    ret

skip_whitespace:
    ; Skip whitespace and comments
    push esi
    
    mov esi, [current_pos]
    
.loop:
    cmp esi, [source_end]
    jge .done
    
    mov al, [esi]
    
    ; Check for space, tab
    cmp al, ' '
    je .skip_char
    cmp al, 9           ; Tab
    je .skip_char
    
    ; Check for newline
    cmp al, 10          ; LF
    je .newline
    cmp al, 13          ; CR
    je .carriage_return
    
    ; Check for comment start (#)
    cmp al, '#'
    je .skip_comment
    
    ; Not whitespace
    jmp .done

.skip_char:
    inc esi
    inc dword [current_column]
    jmp .loop

.newline:
    inc esi
    inc dword [current_line]
    mov dword [current_column], 1
    jmp .loop

.carriage_return:
    inc esi
    ; Check if followed by LF
    cmp esi, [source_end]
    jge .cr_done
    cmp byte [esi], 10
    jne .cr_done
    inc esi             ; Skip LF too
.cr_done:
    inc dword [current_line]
    mov dword [current_column], 1
    jmp .loop

.skip_comment:
    ; Skip until end of line
.comment_loop:
    inc esi
    cmp esi, [source_end]
    jge .done
    mov al, [esi]
    cmp al, 10          ; LF
    je .newline
    cmp al, 13          ; CR
    je .carriage_return
    jmp .comment_loop

.done:
    mov [current_pos], esi
    pop esi
    ret

is_keyword:
    ; Check if string in EAX is a keyword
    ; Returns keyword ID in EAX, or 0 if not a keyword
    push ebx
    push ecx
    push esi
    
    mov esi, eax        ; String to check
    mov ebx, keywords   ; Keyword table
    
.loop:
    mov ecx, [ebx]      ; Keyword string pointer
    test ecx, ecx
    jz .not_found       ; End of table
    
    ; Compare strings
    mov eax, esi
    call string_compare
    test eax, eax
    jz .found
    
    add ebx, 8          ; Next entry (pointer + ID)
    jmp .loop

.found:
    mov eax, [ebx + 4]  ; Return keyword ID
    jmp .exit

.not_found:
    mov eax, 0

.exit:
    pop esi
    pop ecx
    pop ebx
    ret

is_operator:
    ; Check if character in AL is an operator
    ; Returns 1 if operator, 0 if not
    cmp al, '+'
    je .is_op
    cmp al, '-'
    je .is_op
    cmp al, '*'
    je .is_op
    cmp al, '/'
    je .is_op
    cmp al, '%'
    je .is_op
    cmp al, '='
    je .is_op
    cmp al, '!'
    je .is_op
    cmp al, '<'
    je .is_op
    cmp al, '>'
    je .is_op
    cmp al, '&'
    je .is_op
    cmp al, '|'
    je .is_op
    
    mov eax, 0
    ret

.is_op:
    mov eax, 1
    ret
