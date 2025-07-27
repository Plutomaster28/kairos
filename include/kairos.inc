; kairos.inc - Main include file for the Kairos interpreter
; Contains constants, macros, and data structures

%ifndef KAIROS_INC
%define KAIROS_INC

; Use 64-bit by default
default rel

; System constants
%define NULL 0
%define TRUE 1
%define FALSE 0

; Memory constants
%define HEAP_SIZE 65536         ; 64KB heap
%define STACK_SIZE 8192         ; 8KB stack
%define MAX_STRING_LEN 4096     ; Maximum string length
%define MAX_TOKENS 1024         ; Maximum tokens per line

; Token types
%define TOKEN_EOF 0
%define TOKEN_IDENTIFIER 1
%define TOKEN_NUMBER 2
%define TOKEN_STRING 3
%define TOKEN_OPERATOR 4
%define TOKEN_KEYWORD 5
%define TOKEN_DELIMITER 6
%define TOKEN_NEWLINE 7
%define TOKEN_COMMENT 8

; Keywords
%define KW_IF 1
%define KW_ELSE 2
%define KW_WHILE 3
%define KW_FOR 4
%define KW_FUNCTION 5
%define KW_RETURN 6
%define KW_LOCAL 7
%define KW_GLOBAL 8
%define KW_PRINT 9
%define KW_INPUT 10

; Operators
%define OP_ASSIGN 1     ; =
%define OP_PLUS 2       ; +
%define OP_MINUS 3      ; -
%define OP_MULTIPLY 4   ; *
%define OP_DIVIDE 5     ; /
%define OP_MODULO 6     ; %
%define OP_EQUAL 7      ; ==
%define OP_NOT_EQUAL 8  ; !=
%define OP_LESS 9       ; <
%define OP_GREATER 10   ; >
%define OP_LESS_EQ 11   ; <=
%define OP_GREATER_EQ 12; >=
%define OP_AND 13       ; &&
%define OP_OR 14        ; ||
%define OP_NOT 15       ; !

; Data types
%define TYPE_NIL 0
%define TYPE_NUMBER 1
%define TYPE_STRING 2
%define TYPE_BOOLEAN 3
%define TYPE_TABLE 4
%define TYPE_FUNCTION 5

; AST Node types
%define AST_PROGRAM 1
%define AST_STATEMENT 2
%define AST_EXPRESSION 3
%define AST_IDENTIFIER 4
%define AST_NUMBER 5
%define AST_STRING 6
%define AST_BINARY_OP 7
%define AST_UNARY_OP 8
%define AST_ASSIGNMENT 9
%define AST_IF 10
%define AST_WHILE 11
%define AST_FUNCTION_CALL 12
%define AST_FUNCTION_DEF 13
%define AST_RETURN 14
%define AST_BLOCK 15

; Error codes
%define ERR_NONE 0
%define ERR_SYNTAX 1
%define ERR_MEMORY 2
%define ERR_TYPE 3
%define ERR_RUNTIME 4
%define ERR_FILE 5

; Structure definitions
struc Token
    .type:      resq 1      ; Token type
    .value:     resq 1      ; Pointer to value string
    .line:      resq 1      ; Line number
    .column:    resq 1      ; Column number
endstruc

struc KairosValue
    .type:      resq 1      ; Value type
    .data:      resq 1      ; Data (number, string pointer, etc.)
    .next:      resq 1      ; For linked lists
endstruc

struc Variable
    .name:      resq 1      ; Variable name pointer
    .value:     resb KairosValue_size
    .next:      resq 1      ; Next variable in scope
endstruc

; AST Node structure
struc ASTNode
    .type:      resq 1      ; Node type
    .value:     resq 1      ; Node value (for literals)
    .left:      resq 1      ; Left child
    .right:     resq 1      ; Right child
    .next:      resq 1      ; Next sibling (for statements)
endstruc

; Macros for common operations
%macro PUSH_ALL 0
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
%endmacro

%macro POP_ALL 0
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
%endmacro

%macro SYSCALL 1
    mov eax, %1
    int 0x80
%endmacro

; String comparison macro
%macro STRCMP 3
    push esi
    push edi
    mov esi, %1
    mov edi, %2
    mov ecx, %3
    repe cmpsb
    pop edi
    pop esi
%endmacro

; Memory allocation macro
%macro MALLOC 2
    mov eax, %1
    call malloc
    mov %2, eax
%endmacro

%endif ; KAIROS_INC
