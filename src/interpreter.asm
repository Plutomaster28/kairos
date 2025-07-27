; interpreter.asm - Core interpreter for Kairos programming language
; Executes the Abstract Syntax Tree

%include "kairos.inc"

section .data
    runtime_error_msg db 'Runtime error', 0
    division_by_zero_msg db 'Division by zero', 0
    undefined_variable_msg db 'Undefined variable', 0

section .bss
    global_variables resd 1     ; Global variable table
    local_variables resd 1      ; Local variable stack
    call_stack resd 1           ; Function call stack
    stack_pointer resd 1        ; Current stack position

section .text
    global interpreter_init
    global interpreter_run
    global evaluate_node
    global execute_statement
    global create_variable
    global lookup_variable
    global create_kairos_value
    
    extern malloc
    extern print_string
    extern string_compare

interpreter_init:
    ; Initialize interpreter state
    push eax
    push ebx
    
    ; Initialize variable tables
    mov dword [global_variables], 0
    mov dword [local_variables], 0
    mov dword [call_stack], 0
    mov dword [stack_pointer], 0
    
    pop ebx
    pop eax
    ret

interpreter_run:
    ; Run the interpreter on source code
    ; EAX = source code string
    push ebx
    push ecx
    push edx
    
    ; For now, just print a message and exit
    push eax
    mov eax, hello_interpreter_msg
    call print_string
    pop eax
    
    ; TODO: Implement full interpreter pipeline:
    ; 1. Initialize lexer with source code
    ; 2. Parse tokens into AST
    ; 3. Execute AST
    
    pop edx
    pop ecx
    pop ebx
    ret

evaluate_node:
    ; Evaluate an AST node and return its value
    ; EAX = AST node pointer
    ; Returns KairosValue in EAX
    push ebx
    push ecx
    push edx
    
    test eax, eax
    jz .error
    
    mov ebx, [eax + ASTNode.type]
    
    cmp ebx, AST_NUMBER
    je .eval_number
    cmp ebx, AST_STRING
    je .eval_string
    cmp ebx, AST_IDENTIFIER
    je .eval_identifier
    cmp ebx, AST_BINARY_OP
    je .eval_binary_op
    cmp ebx, AST_UNARY_OP
    je .eval_unary_op
    
    ; Unknown node type
    jmp .error

.eval_number:
    ; Create number value
    call create_kairos_value
    test eax, eax
    jz .error
    
    mov dword [eax + KairosValue.type], TYPE_NUMBER
    mov ebx, [esp + 12]     ; Original node pointer
    mov ebx, [ebx + ASTNode.value]
    mov [eax + KairosValue.data], ebx
    jmp .done

.eval_string:
    call create_kairos_value
    test eax, eax
    jz .error
    
    mov dword [eax + KairosValue.type], TYPE_STRING
    mov ebx, [esp + 12]
    mov ebx, [ebx + ASTNode.value]
    mov [eax + KairosValue.data], ebx
    jmp .done

.eval_identifier:
    ; Look up variable value
    mov ebx, [esp + 12]
    mov eax, [ebx + ASTNode.value]
    call lookup_variable
    jmp .done

.eval_binary_op:
    ; Evaluate binary operation
    mov esi, [esp + 12]     ; Node pointer
    
    ; Evaluate left operand
    mov eax, [esi + ASTNode.left]
    call evaluate_node
    test eax, eax
    jz .error
    push eax                ; Save left value
    
    ; Evaluate right operand
    mov eax, [esi + ASTNode.right]
    call evaluate_node
    test eax, eax
    jz .error_cleanup
    
    mov ecx, eax            ; Right value
    pop ebx                 ; Left value
    
    ; Get operator type
    mov edx, [esi + ASTNode.value]
    
    ; Perform operation based on operator type
    cmp edx, OP_PLUS
    je .add_values
    cmp edx, OP_MINUS
    je .subtract_values
    cmp edx, OP_MULTIPLY
    je .multiply_values
    cmp edx, OP_DIVIDE
    je .divide_values
    cmp edx, OP_EQUAL
    je .compare_equal
    cmp edx, OP_NOT_EQUAL
    je .compare_not_equal
    
    ; Unknown operator
    jmp .error

.add_values:
    call add_kairos_values
    jmp .done

.subtract_values:
    call subtract_kairos_values
    jmp .done

.multiply_values:
    call multiply_kairos_values
    jmp .done

.divide_values:
    call divide_kairos_values
    jmp .done

.compare_equal:
    call compare_kairos_values_equal
    jmp .done

.compare_not_equal:
    call compare_kairos_values_equal
    test eax, eax
    jnz .make_false
    
    ; Make true value
    call create_kairos_value
    test eax, eax
    jz .error
    mov dword [eax + KairosValue.type], TYPE_BOOLEAN
    mov dword [eax + KairosValue.data], TRUE
    jmp .done

.make_false:
    call create_kairos_value
    test eax, eax
    jz .error
    mov dword [eax + KairosValue.type], TYPE_BOOLEAN
    mov dword [eax + KairosValue.data], FALSE
    jmp .done

.eval_unary_op:
    ; TODO: Implement unary operations
    jmp .error

.error_cleanup:
    add esp, 4              ; Clean up stack

.error:
    mov eax, 0

.done:
    pop edx
    pop ecx
    pop ebx
    ret

execute_statement:
    ; Execute a statement node
    ; EAX = AST node pointer
    push ebx
    push ecx
    
    test eax, eax
    jz .done
    
    mov ebx, [eax + ASTNode.type]
    
    cmp ebx, AST_ASSIGNMENT
    je .exec_assignment
    cmp ebx, AST_IF
    je .exec_if
    cmp ebx, AST_WHILE
    je .exec_while
    cmp ebx, AST_FUNCTION_CALL
    je .exec_function_call
    cmp ebx, AST_RETURN
    je .exec_return
    
    ; Default: evaluate as expression
    call evaluate_node

.done:
    pop ecx
    pop ebx
    ret

.exec_assignment:
    ; TODO: Implement assignment
    jmp .done

.exec_if:
    ; TODO: Implement if statement
    jmp .done

.exec_while:
    ; TODO: Implement while loop
    jmp .done

.exec_function_call:
    ; TODO: Implement function call
    jmp .done

.exec_return:
    ; TODO: Implement return statement
    jmp .done

create_kairos_value:
    ; Create a new KairosValue structure
    ; Returns pointer in EAX
    push ebx
    
    mov eax, KairosValue_size
    call malloc
    test eax, eax
    jz .error
    
    ; Initialize to NIL
    mov dword [eax + KairosValue.type], TYPE_NIL
    mov dword [eax + KairosValue.data], 0
    mov dword [eax + KairosValue.next], 0
    
    jmp .exit

.error:
    mov eax, 0

.exit:
    pop ebx
    ret

create_variable:
    ; Create a new variable
    ; EAX = variable name string
    ; EBX = KairosValue pointer
    ; Returns Variable pointer in EAX
    push ecx
    push edx
    
    mov ecx, eax            ; Save name
    mov edx, ebx            ; Save value
    
    ; Allocate variable structure
    mov eax, Variable_size
    call malloc
    test eax, eax
    jz .error
    
    ; Set name and value
    mov [eax + Variable.name], ecx
    ; Copy value
    push esi
    push edi
    lea esi, [edx]          ; Source value
    lea edi, [eax + Variable.value]  ; Destination
    mov ecx, KairosValue_size
    rep movsb
    pop edi
    pop esi
    
    mov dword [eax + Variable.next], 0
    jmp .exit

.error:
    mov eax, 0

.exit:
    pop edx
    pop ecx
    ret

lookup_variable:
    ; Look up variable by name
    ; EAX = variable name string
    ; Returns KairosValue pointer in EAX, or 0 if not found
    push ebx
    push ecx
    
    mov ebx, eax            ; Variable name
    
    ; First check local variables
    mov ecx, [local_variables]
    call search_variable_list
    test eax, eax
    jnz .found
    
    ; Then check global variables
    mov ecx, [global_variables]
    call search_variable_list
    test eax, eax
    jnz .found
    
    ; Variable not found
    mov eax, 0
    jmp .exit

.found:
    ; Return pointer to variable's value
    lea eax, [eax + Variable.value]

.exit:
    pop ecx
    pop ebx
    ret

search_variable_list:
    ; Search for variable in linked list
    ; EBX = variable name
    ; ECX = list head
    ; Returns Variable pointer in EAX, or 0 if not found
    push edx
    
    mov eax, ecx            ; Current variable
    
.loop:
    test eax, eax
    jz .not_found
    
    ; Compare names
    push eax
    push ebx
    mov eax, ebx
    mov ebx, [eax + Variable.name]
    call string_compare
    pop ebx
    pop eax
    
    test edx, edx           ; string_compare result
    jz .found
    
    ; Next variable
    mov eax, [eax + Variable.next]
    jmp .loop

.found:
    jmp .exit

.not_found:
    mov eax, 0

.exit:
    pop edx
    ret

; Arithmetic operations
add_kairos_values:
    ; Add two KairosValues
    ; EBX = left value, ECX = right value
    ; Returns new KairosValue in EAX
    push edx
    
    ; For now, only handle numbers
    cmp dword [ebx + KairosValue.type], TYPE_NUMBER
    jne .error
    cmp dword [ecx + KairosValue.type], TYPE_NUMBER
    jne .error
    
    ; Create result value
    call create_kairos_value
    test eax, eax
    jz .error
    
    mov dword [eax + KairosValue.type], TYPE_NUMBER
    
    ; Add the numbers (assuming they're integers for simplicity)
    mov edx, [ebx + KairosValue.data]
    add edx, [ecx + KairosValue.data]
    mov [eax + KairosValue.data], edx
    
    jmp .exit

.error:
    mov eax, 0

.exit:
    pop edx
    ret

subtract_kairos_values:
    ; Subtract two KairosValues
    push edx
    
    cmp dword [ebx + KairosValue.type], TYPE_NUMBER
    jne .error
    cmp dword [ecx + KairosValue.type], TYPE_NUMBER
    jne .error
    
    call create_kairos_value
    test eax, eax
    jz .error
    
    mov dword [eax + KairosValue.type], TYPE_NUMBER
    mov edx, [ebx + KairosValue.data]
    sub edx, [ecx + KairosValue.data]
    mov [eax + KairosValue.data], edx
    
    jmp .exit

.error:
    mov eax, 0

.exit:
    pop edx
    ret

multiply_kairos_values:
    ; Multiply two KairosValues
    push edx
    
    cmp dword [ebx + KairosValue.type], TYPE_NUMBER
    jne .error
    cmp dword [ecx + KairosValue.type], TYPE_NUMBER
    jne .error
    
    call create_kairos_value
    test eax, eax
    jz .error
    
    mov dword [eax + KairosValue.type], TYPE_NUMBER
    mov eax, [ebx + KairosValue.data]
    imul eax, [ecx + KairosValue.data]
    mov edx, [esp + 4]      ; Get back result pointer
    mov [edx + KairosValue.data], eax
    mov eax, edx
    
    jmp .exit

.error:
    mov eax, 0

.exit:
    pop edx
    ret

divide_kairos_values:
    ; Divide two KairosValues
    push edx
    
    cmp dword [ebx + KairosValue.type], TYPE_NUMBER
    jne .error
    cmp dword [ecx + KairosValue.type], TYPE_NUMBER
    jne .error
    
    ; Check for division by zero
    cmp dword [ecx + KairosValue.data], 0
    je .division_by_zero
    
    call create_kairos_value
    test eax, eax
    jz .error
    
    mov dword [eax + KairosValue.type], TYPE_NUMBER
    push eax                ; Save result pointer
    mov eax, [ebx + KairosValue.data]
    cdq                     ; Sign extend EAX to EDX:EAX
    idiv dword [ecx + KairosValue.data]
    pop edx                 ; Get result pointer back
    mov [edx + KairosValue.data], eax
    mov eax, edx
    
    jmp .exit

.division_by_zero:
    ; TODO: Proper error handling
    mov eax, division_by_zero_msg
    call print_string
    
.error:
    mov eax, 0

.exit:
    pop edx
    ret

compare_kairos_values_equal:
    ; Compare two KairosValues for equality
    ; EBX = left value, ECX = right value
    ; Returns 1 if equal, 0 if not equal
    push edx
    
    ; Check if types are the same
    mov eax, [ebx + KairosValue.type]
    cmp eax, [ecx + KairosValue.type]
    jne .not_equal
    
    ; Compare based on type
    cmp eax, TYPE_NUMBER
    je .compare_numbers
    cmp eax, TYPE_STRING
    je .compare_strings
    cmp eax, TYPE_BOOLEAN
    je .compare_booleans
    cmp eax, TYPE_NIL
    je .equal               ; All NIL values are equal
    
    ; Unknown type
.not_equal:
    mov eax, 0
    jmp .exit

.compare_numbers:
    mov eax, [ebx + KairosValue.data]
    cmp eax, [ecx + KairosValue.data]
    je .equal
    jmp .not_equal

.compare_booleans:
    mov eax, [ebx + KairosValue.data]
    cmp eax, [ecx + KairosValue.data]
    je .equal
    jmp .not_equal

.compare_strings:
    mov eax, [ebx + KairosValue.data]
    push ebx
    mov ebx, [ecx + KairosValue.data]
    call string_compare
    pop ebx
    test eax, eax
    jz .equal
    jmp .not_equal

.equal:
    mov eax, 1

.exit:
    pop edx
    ret

section .data
    hello_interpreter_msg db 'Kairos interpreter starting...', 0Ah, 0
