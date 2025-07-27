; builtins.asm - Built-in functions for Kairos programming language
; Implementation of core functions like print, input, string operations, etc.

%include "kairos.inc"

section .data
    print_buffer resb 1024  ; Buffer for print formatting
    newline_str db 0Ah, 0
    
section .text
    global builtin_print
    global builtin_input
    global builtin_len
    global builtin_type
    global builtin_str
    global builtin_num
    global call_builtin
    
    extern print_string
    extern string_length
    extern kairos_malloc
    extern create_kairos_value
    extern string_compare

builtin_print:
    ; Print function implementation
    ; EAX = KairosValue to print
    push eax
    push ebx
    push ecx
    
    test eax, eax
    jz .print_nil
    
    mov ebx, [eax + KairosValue.type]
    
    cmp ebx, TYPE_STRING
    je .print_string
    cmp ebx, TYPE_NUMBER
    je .print_number
    cmp ebx, TYPE_BOOLEAN
    je .print_boolean
    cmp ebx, TYPE_NIL
    je .print_nil
    
    ; Unknown type, print as string representation
    jmp .print_unknown

.print_string:
    mov eax, [eax + KairosValue.data]
    call print_string
    jmp .print_newline

.print_number:
    ; Convert number to string and print
    mov eax, [eax + KairosValue.data]
    call number_to_string
    call print_string
    jmp .print_newline

.print_boolean:
    mov eax, [eax + KairosValue.data]
    test eax, eax
    jz .print_false
    
.print_true:
    mov eax, true_str
    call print_string
    jmp .print_newline

.print_false:
    mov eax, false_str
    call print_string
    jmp .print_newline

.print_nil:
    mov eax, nil_str
    call print_string
    jmp .print_newline

.print_unknown:
    mov eax, unknown_str
    call print_string

.print_newline:
    mov eax, newline_str
    call print_string

.done:
    pop ecx
    pop ebx
    pop eax
    ret

builtin_input:
    ; Input function - read a line from stdin
    ; Returns KairosValue containing the input string
    push ebx
    push ecx
    push edx
    
    ; Allocate buffer for input
    mov eax, 256            ; Max input length
    call kairos_malloc
    test eax, eax
    jz .error
    mov ebx, eax            ; Save buffer pointer
    
    ; Read from stdin
    mov eax, 3              ; sys_read
    mov ecx, ebx            ; Buffer
    mov edx, 255            ; Max bytes to read
    push ebx                ; Save buffer
    mov ebx, 0              ; stdin
    int 0x80
    pop ebx
    
    test eax, eax
    jl .error
    
    ; Null-terminate the input (remove newline if present)
    cmp eax, 0
    je .empty_input
    
    dec eax                 ; Point to last character
    cmp byte [ebx + eax], 0Ah
    jne .no_newline
    mov byte [ebx + eax], 0 ; Replace newline with null
    jmp .create_value

.no_newline:
    inc eax                 ; Point after last character
    mov byte [ebx + eax], 0 ; Null terminate

.create_value:
    ; Create KairosValue for the string
    call create_kairos_value
    test eax, eax
    jz .error
    
    mov dword [eax + KairosValue.type], TYPE_STRING
    mov [eax + KairosValue.data], ebx
    jmp .exit

.empty_input:
    mov byte [ebx], 0       ; Empty string
    jmp .create_value

.error:
    mov eax, 0

.exit:
    pop edx
    pop ecx
    pop ebx
    ret

builtin_len:
    ; Length function - returns length of string or table
    ; EAX = KairosValue
    ; Returns KairosValue containing the length
    push ebx
    push ecx
    
    test eax, eax
    jz .error
    
    mov ebx, [eax + KairosValue.type]
    
    cmp ebx, TYPE_STRING
    je .string_length
    cmp ebx, TYPE_TABLE
    je .table_length
    
    ; Unsupported type
    jmp .error

.string_length:
    mov eax, [eax + KairosValue.data]
    call string_length
    jmp .create_number_result

.table_length:
    ; TODO: Implement table length calculation
    mov eax, 0
    jmp .create_number_result

.create_number_result:
    push eax                ; Save length
    call create_kairos_value
    test eax, eax
    jz .error_cleanup
    
    mov dword [eax + KairosValue.type], TYPE_NUMBER
    pop ebx                 ; Get length
    mov [eax + KairosValue.data], ebx
    jmp .exit

.error_cleanup:
    add esp, 4              ; Clean up stack

.error:
    mov eax, 0

.exit:
    pop ecx
    pop ebx
    ret

builtin_type:
    ; Type function - returns string representation of value type
    ; EAX = KairosValue
    ; Returns KairosValue containing type name string
    push ebx
    push ecx
    
    test eax, eax
    jz .nil_type
    
    mov ebx, [eax + KairosValue.type]
    
    cmp ebx, TYPE_STRING
    je .string_type
    cmp ebx, TYPE_NUMBER
    je .number_type
    cmp ebx, TYPE_BOOLEAN
    je .boolean_type
    cmp ebx, TYPE_TABLE
    je .table_type
    cmp ebx, TYPE_FUNCTION
    je .function_type
    cmp ebx, TYPE_NIL
    je .nil_type
    
    ; Unknown type
    mov eax, unknown_type_str
    jmp .create_string_result

.string_type:
    mov eax, string_type_str
    jmp .create_string_result

.number_type:
    mov eax, number_type_str
    jmp .create_string_result

.boolean_type:
    mov eax, boolean_type_str
    jmp .create_string_result

.table_type:
    mov eax, table_type_str
    jmp .create_string_result

.function_type:
    mov eax, function_type_str
    jmp .create_string_result

.nil_type:
    mov eax, nil_type_str

.create_string_result:
    push eax                ; Save type string
    call create_kairos_value
    test eax, eax
    jz .error_cleanup
    
    mov dword [eax + KairosValue.type], TYPE_STRING
    pop ebx                 ; Get type string
    mov [eax + KairosValue.data], ebx
    jmp .exit

.error_cleanup:
    add esp, 4

.error:
    mov eax, 0

.exit:
    pop ecx
    pop ebx
    ret

builtin_str:
    ; Convert value to string representation
    ; EAX = KairosValue
    ; Returns KairosValue containing string representation
    push ebx
    push ecx
    push edx
    
    test eax, eax
    jz .nil_string
    
    mov ebx, [eax + KairosValue.type]
    
    cmp ebx, TYPE_STRING
    je .already_string
    cmp ebx, TYPE_NUMBER
    je .number_to_string
    cmp ebx, TYPE_BOOLEAN
    je .boolean_to_string
    cmp ebx, TYPE_NIL
    je .nil_string
    
    ; Unknown type
    mov eax, unknown_str
    jmp .create_string_result

.already_string:
    ; Just return a copy
    jmp .exit

.number_to_string:
    mov eax, [eax + KairosValue.data]
    call number_to_string
    jmp .create_string_result

.boolean_to_string:
    mov eax, [eax + KairosValue.data]
    test eax, eax
    jz .false_string
    mov eax, true_str
    jmp .create_string_result

.false_string:
    mov eax, false_str
    jmp .create_string_result

.nil_string:
    mov eax, nil_str

.create_string_result:
    ; EAX contains string pointer
    push eax                ; Save string
    call create_kairos_value
    test eax, eax
    jz .error_cleanup
    
    mov dword [eax + KairosValue.type], TYPE_STRING
    pop ebx                 ; Get string
    mov [eax + KairosValue.data], ebx
    jmp .exit

.error_cleanup:
    add esp, 4

.error:
    mov eax, 0

.exit:
    pop edx
    pop ecx
    pop ebx
    ret

builtin_num:
    ; Convert value to number
    ; EAX = KairosValue
    ; Returns KairosValue containing number representation
    push ebx
    push ecx
    
    test eax, eax
    jz .zero_result
    
    mov ebx, [eax + KairosValue.type]
    
    cmp ebx, TYPE_NUMBER
    je .already_number
    cmp ebx, TYPE_STRING
    je .string_to_number
    cmp ebx, TYPE_BOOLEAN
    je .boolean_to_number
    cmp ebx, TYPE_NIL
    je .zero_result
    
    ; Unknown type - return 0
    jmp .zero_result

.already_number:
    ; Just return the same value
    jmp .exit

.string_to_number:
    mov eax, [eax + KairosValue.data]
    call string_to_number
    jmp .create_number_result

.boolean_to_number:
    mov eax, [eax + KairosValue.data]
    ; true = 1, false = 0
    jmp .create_number_result

.zero_result:
    mov eax, 0

.create_number_result:
    push eax                ; Save number
    call create_kairos_value
    test eax, eax
    jz .error_cleanup
    
    mov dword [eax + KairosValue.type], TYPE_NUMBER
    pop ebx                 ; Get number
    mov [eax + KairosValue.data], ebx
    jmp .exit

.error_cleanup:
    add esp, 4

.error:
    mov eax, 0

.exit:
    pop ecx
    pop ebx
    ret

call_builtin:
    ; Call a built-in function by name
    ; EAX = function name string
    ; EBX = argument array
    ; ECX = argument count
    ; Returns result in EAX
    push edx
    push esi
    push edi
    
    ; Check function name
    mov edx, eax
    
    ; Compare with known built-in names
    mov eax, print_name
    call string_compare
    test eax, eax
    jz .call_print
    
    mov eax, input_name
    call string_compare
    test eax, eax
    jz .call_input
    
    mov eax, len_name
    call string_compare
    test eax, eax
    jz .call_len
    
    mov eax, type_name
    call string_compare
    test eax, eax
    jz .call_type
    
    mov eax, str_name
    call string_compare
    test eax, eax
    jz .call_str
    
    mov eax, num_name
    call string_compare
    test eax, eax
    jz .call_num
    
    ; Unknown function
    jmp .error

.call_print:
    ; Print takes one argument
    cmp ecx, 1
    jne .error
    mov eax, [ebx]          ; First argument
    call builtin_print
    ; Return nil
    call create_kairos_value
    mov dword [eax + KairosValue.type], TYPE_NIL
    jmp .exit

.call_input:
    ; Input takes no arguments
    cmp ecx, 0
    jne .error
    call builtin_input
    jmp .exit

.call_len:
    cmp ecx, 1
    jne .error
    mov eax, [ebx]
    call builtin_len
    jmp .exit

.call_type:
    cmp ecx, 1
    jne .error
    mov eax, [ebx]
    call builtin_type
    jmp .exit

.call_str:
    cmp ecx, 1
    jne .error
    mov eax, [ebx]
    call builtin_str
    jmp .exit

.call_num:
    cmp ecx, 1
    jne .error
    mov eax, [ebx]
    call builtin_num
    jmp .exit

.error:
    mov eax, 0

.exit:
    pop edi
    pop esi
    pop edx
    ret

; Helper functions
number_to_string:
    ; Convert number in EAX to string
    ; Returns pointer to string in EAX
    push ebx
    push ecx
    push edx
    
    ; Allocate buffer for string representation
    mov ebx, 32             ; Should be enough for most numbers
    push eax                ; Save number
    mov eax, ebx
    call kairos_malloc
    test eax, eax
    jz .error
    
    mov ebx, eax            ; Buffer pointer
    pop eax                 ; Restore number
    
    ; Convert number to string (simple implementation)
    push ebx
    call simple_itoa
    pop eax                 ; Return buffer pointer
    jmp .exit

.error:
    add esp, 4              ; Clean up stack
    mov eax, 0

.exit:
    pop edx
    pop ecx
    pop ebx
    ret

simple_itoa:
    ; Convert integer in EAX to string in buffer EBX
    ; Simple implementation for positive numbers
    push ecx
    push edx
    push esi
    push edi
    
    mov esi, ebx            ; Buffer
    mov edi, ebx            ; Start of buffer
    
    ; Handle zero
    test eax, eax
    jnz .not_zero
    mov byte [esi], '0'
    inc esi
    jmp .null_terminate

.not_zero:
    ; Handle negative numbers
    test eax, eax
    jns .positive
    mov byte [esi], '-'
    inc esi
    neg eax

.positive:
    ; Convert digits (in reverse order)
    mov ecx, 10
.digit_loop:
    test eax, eax
    jz .reverse_digits
    
    xor edx, edx
    div ecx                 ; EAX = quotient, EDX = remainder
    add dl, '0'             ; Convert to ASCII
    mov [esi], dl
    inc esi
    jmp .digit_loop

.reverse_digits:
    ; Reverse the digits (except for sign)
    dec esi                 ; Point to last digit
    mov ecx, edi            ; Start of number part
    cmp byte [edi], '-'
    jne .start_reverse
    inc ecx                 ; Skip sign

.start_reverse:
    cmp ecx, esi
    jge .null_terminate
    
    ; Swap characters
    mov al, [ecx]
    mov dl, [esi]
    mov [ecx], dl
    mov [esi], al
    
    inc ecx
    dec esi
    jmp .start_reverse

.null_terminate:
    mov byte [esi], 0

    pop edi
    pop esi
    pop edx
    pop ecx
    ret

string_to_number:
    ; Convert string in EAX to number
    ; Returns number in EAX
    push ebx
    push ecx
    push edx
    push esi
    
    mov esi, eax            ; String pointer
    xor eax, eax            ; Result
    xor ebx, ebx            ; Sign flag
    mov ecx, 10             ; Base
    
    ; Skip whitespace
.skip_space:
    mov dl, [esi]
    cmp dl, ' '
    je .next_char
    cmp dl, 9               ; Tab
    je .next_char
    jmp .check_sign

.next_char:
    inc esi
    jmp .skip_space

.check_sign:
    mov dl, [esi]
    cmp dl, '-'
    jne .check_plus
    mov ebx, 1              ; Negative
    inc esi
    jmp .parse_digits

.check_plus:
    cmp dl, '+'
    jne .parse_digits
    inc esi

.parse_digits:
    mov dl, [esi]
    test dl, dl
    jz .done
    
    ; Check if digit
    cmp dl, '0'
    jb .done
    cmp dl, '9'
    ja .done
    
    ; Convert digit
    sub dl, '0'
    
    ; Multiply result by 10 and add digit
    mul ecx                 ; EAX = EAX * 10
    add eax, edx
    
    inc esi
    jmp .parse_digits

.done:
    ; Apply sign
    test ebx, ebx
    jz .exit
    neg eax

.exit:
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

section .data
    true_str db 'true', 0
    false_str db 'false', 0
    nil_str db 'nil', 0
    unknown_str db '<unknown>', 0
    
    string_type_str db 'string', 0
    number_type_str db 'number', 0
    boolean_type_str db 'boolean', 0
    table_type_str db 'table', 0
    function_type_str db 'function', 0
    nil_type_str db 'nil', 0
    unknown_type_str db 'unknown', 0
    
    ; Built-in function names
    print_name db 'print', 0
    input_name db 'input', 0
    len_name db 'len', 0
    type_name db 'type', 0
    str_name db 'str', 0
    num_name db 'num', 0
