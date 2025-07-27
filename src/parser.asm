; parser.asm - Parser for the Kairos programming language
; Builds an Abstract Syntax Tree from tokens

%include "kairos.inc"

section .data
    parse_error_msg db 'Parse error', 0

section .bss
    current_token resd 1    ; Current token being processed
    token_stream resd 1     ; Array of tokens
    token_index resd 1      ; Current position in token stream
    ast_root resd 1         ; Root of the AST

section .text
    global parser_init
    global parse_program
    global parse_statement
    global parse_expression
    global create_ast_node
    
    extern malloc
    extern next_token

parser_init:
    ; Initialize parser
    push eax
    push ebx
    
    ; Reset parser state
    mov dword [current_token], 0
    mov dword [token_stream], 0
    mov dword [token_index], 0
    mov dword [ast_root], 0
    
    pop ebx
    pop eax
    ret

parse_program:
    ; Parse entire program
    ; Returns AST root in EAX
    push ebx
    push ecx
    push edx
    
    ; Create program node
    mov eax, AST_PROGRAM
    call create_ast_node
    test eax, eax
    jz .error
    mov [ast_root], eax
    mov ebx, eax            ; Save program node
    
    ; Parse statements until EOF
.parse_loop:
    call next_token
    test eax, eax
    jz .done                ; EOF reached
    
    mov [current_token], eax
    call parse_statement
    test eax, eax
    jz .error
    
    ; Link statement to program
    cmp dword [ebx + ASTNode.left], 0
    jne .append_statement
    
    ; First statement
    mov [ebx + ASTNode.left], eax
    jmp .parse_loop

.append_statement:
    ; Find last statement and append
    push esi
    mov esi, [ebx + ASTNode.left]
.find_last:
    cmp dword [esi + ASTNode.next], 0
    je .append
    mov esi, [esi + ASTNode.next]
    jmp .find_last
.append:
    mov [esi + ASTNode.next], eax
    pop esi
    jmp .parse_loop

.done:
    mov eax, [ast_root]
    jmp .exit

.error:
    mov eax, 0

.exit:
    pop edx
    pop ecx
    pop ebx
    ret

parse_statement:
    ; Parse a single statement
    ; Returns AST node in EAX
    push ebx
    push ecx
    
    mov eax, [current_token]
    test eax, eax
    jz .error
    
    ; Check token type
    mov ebx, [eax + Token.type]
    cmp ebx, TOKEN_KEYWORD
    je .parse_keyword_statement
    
    cmp ebx, TOKEN_IDENTIFIER
    je .parse_assignment_or_call
    
    ; Default: try to parse as expression statement
    call parse_expression
    jmp .done

.parse_keyword_statement:
    mov eax, [current_token]
    mov ebx, [eax + Token.value]
    
    ; Check which keyword
    mov eax, ebx
    push ebx
    call check_keyword
    pop ebx
    
    cmp eax, KW_IF
    je .parse_if
    cmp eax, KW_WHILE
    je .parse_while
    cmp eax, KW_FUNCTION
    je .parse_function
    cmp eax, KW_RETURN
    je .parse_return
    cmp eax, KW_PRINT
    je .parse_print
    
    ; Unknown keyword
    jmp .error

.parse_assignment_or_call:
    ; Look ahead to determine if assignment or function call
    call peek_next_token
    test eax, eax
    jz .error
    
    mov ebx, [eax + Token.type]
    cmp ebx, TOKEN_OPERATOR
    jne .parse_function_call
    
    ; Check if assignment operator
    mov ecx, [eax + Token.value]
    cmp byte [ecx], '='
    je .parse_assignment
    
    jmp .parse_function_call

.parse_assignment:
    call parse_assignment_statement
    jmp .done

.parse_function_call:
    call parse_function_call_statement
    jmp .done

.parse_if:
    call parse_if_statement
    jmp .done

.parse_while:
    call parse_while_statement
    jmp .done

.parse_function:
    call parse_function_definition
    jmp .done

.parse_return:
    call parse_return_statement
    jmp .done

.parse_print:
    call parse_print_statement
    jmp .done

.done:
    ; EAX should contain the parsed statement
    jmp .exit

.error:
    mov eax, 0

.exit:
    pop ecx
    pop ebx
    ret

parse_expression:
    ; Parse expression (handles operator precedence)
    ; Returns AST node in EAX
    call parse_logical_or
    ret

parse_logical_or:
    ; Parse logical OR (lowest precedence)
    push ebx
    push ecx
    
    call parse_logical_and
    test eax, eax
    jz .error
    mov ebx, eax            ; Left operand
    
.loop:
    call peek_next_token
    test eax, eax
    jz .done                ; No more tokens
    
    ; Check for || operator
    mov ecx, [eax + Token.type]
    cmp ecx, TOKEN_OPERATOR
    jne .done
    
    mov ecx, [eax + Token.value]
    cmp byte [ecx], '|'
    jne .done
    cmp byte [ecx + 1], '|'
    jne .done
    
    ; Consume the operator
    call next_token
    
    ; Parse right operand
    call parse_logical_and
    test eax, eax
    jz .error
    
    ; Create binary operation node
    push eax                ; Right operand
    push ebx                ; Left operand
    mov eax, AST_BINARY_OP
    call create_ast_node
    test eax, eax
    jz .error_cleanup
    
    pop ebx                 ; Left operand
    mov [eax + ASTNode.left], ebx
    pop ebx                 ; Right operand
    mov [eax + ASTNode.right], ebx
    
    ; Set operator type
    mov dword [eax + ASTNode.value], OP_OR
    
    mov ebx, eax            ; New left operand
    jmp .loop

.done:
    mov eax, ebx
    jmp .exit

.error_cleanup:
    add esp, 8              ; Clean up stack
    
.error:
    mov eax, 0

.exit:
    pop ecx
    pop ebx
    ret

parse_logical_and:
    ; Parse logical AND
    push ebx
    push ecx
    
    call parse_equality
    test eax, eax
    jz .error
    mov ebx, eax
    
.loop:
    call peek_next_token
    test eax, eax
    jz .done
    
    mov ecx, [eax + Token.type]
    cmp ecx, TOKEN_OPERATOR
    jne .done
    
    mov ecx, [eax + Token.value]
    cmp byte [ecx], '&'
    jne .done
    cmp byte [ecx + 1], '&'
    jne .done
    
    call next_token
    call parse_equality
    test eax, eax
    jz .error
    
    push eax
    push ebx
    mov eax, AST_BINARY_OP
    call create_ast_node
    test eax, eax
    jz .error_cleanup
    
    pop ebx
    mov [eax + ASTNode.left], ebx
    pop ebx
    mov [eax + ASTNode.right], ebx
    mov dword [eax + ASTNode.value], OP_AND
    
    mov ebx, eax
    jmp .loop

.done:
    mov eax, ebx
    jmp .exit

.error_cleanup:
    add esp, 8

.error:
    mov eax, 0

.exit:
    pop ecx
    pop ebx
    ret

parse_equality:
    ; Parse equality operations (==, !=)
    push ebx
    push ecx
    
    call parse_comparison
    test eax, eax
    jz .error
    mov ebx, eax
    
.loop:
    call peek_next_token
    test eax, eax
    jz .done
    
    mov ecx, [eax + Token.type]
    cmp ecx, TOKEN_OPERATOR
    jne .done
    
    mov ecx, [eax + Token.value]
    ; Check for ==
    cmp byte [ecx], '='
    je .check_double_equal
    ; Check for !=
    cmp byte [ecx], '!'
    je .check_not_equal
    jmp .done

.check_double_equal:
    cmp byte [ecx + 1], '='
    jne .done
    call next_token
    call parse_comparison
    test eax, eax
    jz .error
    
    push eax
    push ebx
    mov eax, AST_BINARY_OP
    call create_ast_node
    test eax, eax
    jz .error_cleanup
    
    pop ebx
    mov [eax + ASTNode.left], ebx
    pop ebx
    mov [eax + ASTNode.right], ebx
    mov dword [eax + ASTNode.value], OP_EQUAL
    
    mov ebx, eax
    jmp .loop

.check_not_equal:
    cmp byte [ecx + 1], '='
    jne .done
    call next_token
    call parse_comparison
    test eax, eax
    jz .error
    
    push eax
    push ebx
    mov eax, AST_BINARY_OP
    call create_ast_node
    test eax, eax
    jz .error_cleanup
    
    pop ebx
    mov [eax + ASTNode.left], ebx
    pop ebx
    mov [eax + ASTNode.right], ebx
    mov dword [eax + ASTNode.value], OP_NOT_EQUAL
    
    mov ebx, eax
    jmp .loop

.done:
    mov eax, ebx
    jmp .exit

.error_cleanup:
    add esp, 8

.error:
    mov eax, 0

.exit:
    pop ecx
    pop ebx
    ret

parse_comparison:
    ; Parse comparison operations (<, >, <=, >=)
    push ebx
    
    call parse_addition
    test eax, eax
    jz .error
    mov ebx, eax
    
    ; For brevity, just return the addition result
    ; Full implementation would handle <, >, <=, >= operators
    
    mov eax, ebx

.exit:
    pop ebx
    ret

.error:
    mov eax, 0
    jmp .exit

parse_addition:
    ; Parse addition and subtraction
    push ebx
    
    call parse_multiplication
    test eax, eax
    jz .error
    mov ebx, eax
    
    ; For brevity, just return the multiplication result
    ; Full implementation would handle +, - operators
    
    mov eax, ebx

.exit:
    pop ebx
    ret

.error:
    mov eax, 0
    jmp .exit

parse_multiplication:
    ; Parse multiplication, division, and modulo
    push ebx
    
    call parse_primary
    test eax, eax
    jz .error
    mov ebx, eax
    
    ; For brevity, just return the primary result
    ; Full implementation would handle *, /, % operators
    
    mov eax, ebx

.exit:
    pop ebx
    ret

.error:
    mov eax, 0
    jmp .exit

parse_primary:
    ; Parse primary expressions (literals, identifiers, parenthesized expressions)
    push ebx
    
    mov eax, [current_token]
    test eax, eax
    jz .error
    
    mov ebx, [eax + Token.type]
    
    cmp ebx, TOKEN_NUMBER
    je .parse_number
    cmp ebx, TOKEN_STRING
    je .parse_string
    cmp ebx, TOKEN_IDENTIFIER
    je .parse_identifier
    cmp ebx, TOKEN_DELIMITER
    je .check_parentheses
    
    jmp .error

.parse_number:
    mov eax, AST_NUMBER
    call create_ast_node
    test eax, eax
    jz .error
    
    mov ebx, [current_token]
    mov ebx, [ebx + Token.value]
    mov [eax + ASTNode.value], ebx
    jmp .done

.parse_string:
    mov eax, AST_STRING
    call create_ast_node
    test eax, eax
    jz .error
    
    mov ebx, [current_token]
    mov ebx, [ebx + Token.value]
    mov [eax + ASTNode.value], ebx
    jmp .done

.parse_identifier:
    mov eax, AST_IDENTIFIER
    call create_ast_node
    test eax, eax
    jz .error
    
    mov ebx, [current_token]
    mov ebx, [ebx + Token.value]
    mov [eax + ASTNode.value], ebx
    jmp .done

.check_parentheses:
    mov eax, [current_token]
    mov ebx, [eax + Token.value]
    cmp byte [ebx], '('
    jne .error
    
    ; Skip opening parenthesis
    call next_token
    mov [current_token], eax
    
    ; Parse expression inside parentheses
    call parse_expression
    test eax, eax
    jz .error
    
    push eax                ; Save expression result
    
    ; Expect closing parenthesis
    call next_token
    test eax, eax
    jz .error_cleanup
    
    mov ebx, [eax + Token.type]
    cmp ebx, TOKEN_DELIMITER
    jne .error_cleanup
    
    mov ebx, [eax + Token.value]
    cmp byte [ebx], ')'
    jne .error_cleanup
    
    pop eax                 ; Restore expression result
    jmp .done

.error_cleanup:
    add esp, 4              ; Clean up stack

.error:
    mov eax, 0

.done:
.exit:
    pop ebx
    ret

create_ast_node:
    ; Create new AST node
    ; EAX = node type
    ; Returns pointer to node in EAX
    push ebx
    push ecx
    
    mov ebx, eax            ; Save node type
    
    ; Allocate memory for node
    mov eax, ASTNode_size
    call malloc
    test eax, eax
    jz .error
    
    ; Initialize node
    mov [eax + ASTNode.type], ebx
    mov dword [eax + ASTNode.value], 0
    mov dword [eax + ASTNode.left], 0
    mov dword [eax + ASTNode.right], 0
    mov dword [eax + ASTNode.next], 0
    
    jmp .exit

.error:
    mov eax, 0

.exit:
    pop ecx
    pop ebx
    ret

; Stub functions for missing implementations
parse_assignment_statement:
    mov eax, 0
    ret

parse_function_call_statement:
    mov eax, 0
    ret

parse_if_statement:
    mov eax, 0
    ret

parse_while_statement:
    mov eax, 0
    ret

parse_function_definition:
    mov eax, 0
    ret

parse_return_statement:
    mov eax, 0
    ret

parse_print_statement:
    mov eax, 0
    ret

peek_next_token:
    ; Peek at next token without consuming it
    ; Returns token in EAX or 0 if EOF
    mov eax, 0              ; Stub implementation
    ret

check_keyword:
    ; Check if string is a keyword and return keyword ID
    ; EAX = string pointer
    ; Returns keyword ID in EAX or 0 if not keyword
    mov eax, 0              ; Stub implementation
    ret
