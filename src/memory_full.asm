; memory.asm - Advanced memory management for Kairos interpreter
; Implements a simple heap with garbage collection capabilities

bits 64

%include "include/kairos.inc"

default rel

section .data
    heap_start dd 0
    heap_end dd 0
    heap_current dd 0
    heap_size dd HEAP_SIZE
    
    ; Allocation header structure
    ; [size:4][used:1][padding:3][data...]
    ALLOC_HEADER_SIZE equ 8

section .text
    global memory_init
    global kairos_malloc
    global kairos_free
    global garbage_collect
    global mark_and_sweep

memory_init:
    ; Initialize the memory management system
    push eax
    push ebx
    
    ; Allocate heap using system brk
    mov eax, [heap_size]
    call system_malloc
    test eax, eax
    jz .error
    
    mov [heap_start], eax
    mov [heap_current], eax
    
    ; Calculate heap end
    add eax, [heap_size]
    mov [heap_end], eax
    
    ; Initialize first free block
    mov eax, [heap_start]
    mov ebx, [heap_size]
    sub ebx, ALLOC_HEADER_SIZE
    mov [eax], ebx          ; Size
    mov dword [eax + 4], 0  ; Not used
    
    pop ebx
    pop eax
    ret

.error:
    pop ebx
    pop eax
    mov eax, 0
    ret

kairos_malloc:
    ; Allocate memory from Kairos heap
    ; EAX = size requested
    ; Returns pointer to allocated memory in EAX
    push ebx
    push ecx
    push edx
    
    ; Align size to 4-byte boundary
    add eax, 3
    and eax, ~3
    mov ebx, eax            ; Aligned size
    
    ; Find suitable free block
    call find_free_block
    test eax, eax
    jnz .found_block
    
    ; No suitable block found, try garbage collection
    call garbage_collect
    call find_free_block
    test eax, eax
    jz .out_of_memory
    
.found_block:
    ; EAX points to free block header
    mov ecx, [eax]          ; Block size
    
    ; Check if we need to split the block
    mov edx, ebx
    add edx, ALLOC_HEADER_SIZE
    cmp ecx, edx
    jle .use_entire_block
    
    ; Split the block
    push eax                ; Save current block
    add eax, ALLOC_HEADER_SIZE
    add eax, ebx            ; Point to new free block
    
    ; Set up new free block
    mov edx, ecx
    sub edx, ebx
    sub edx, ALLOC_HEADER_SIZE
    mov [eax], edx          ; New block size
    mov dword [eax + 4], 0  ; Not used
    
    pop eax                 ; Restore current block
    mov [eax], ebx          ; Update current block size

.use_entire_block:
    ; Mark block as used
    mov dword [eax + 4], 1
    
    ; Return pointer to data area
    add eax, ALLOC_HEADER_SIZE
    jmp .exit

.out_of_memory:
    mov eax, 0

.exit:
    pop edx
    pop ecx
    pop ebx
    ret

kairos_free:
    ; Free memory allocated by kairos_malloc
    ; EAX = pointer to memory to free
    push eax
    push ebx
    push ecx
    
    ; Get header pointer
    sub eax, ALLOC_HEADER_SIZE
    
    ; Verify it's within our heap
    cmp eax, [heap_start]
    jb .invalid_pointer
    cmp eax, [heap_end]
    jae .invalid_pointer
    
    ; Mark as free
    mov dword [eax + 4], 0
    
    ; Try to merge with adjacent free blocks
    call merge_free_blocks

.invalid_pointer:
    pop ecx
    pop ebx
    pop eax
    ret

find_free_block:
    ; Find a free block of at least EBX bytes
    ; Returns pointer to block header in EAX, or 0 if not found
    push ecx
    push edx
    
    mov eax, [heap_start]
    
.search_loop:
    ; Check if we've reached the end
    cmp eax, [heap_end]
    jae .not_found
    
    ; Check if block is free
    cmp dword [eax + 4], 0
    jne .next_block
    
    ; Check if block is large enough
    mov ecx, [eax]          ; Block size
    cmp ecx, ebx
    jae .found
    
.next_block:
    ; Move to next block
    mov ecx, [eax]          ; Block size
    add eax, ecx
    add eax, ALLOC_HEADER_SIZE
    jmp .search_loop

.found:
    jmp .exit

.not_found:
    mov eax, 0

.exit:
    pop edx
    pop ecx
    ret

merge_free_blocks:
    ; Merge adjacent free blocks starting from EAX
    push ebx
    push ecx
    push edx
    
    ; Current block in EAX
    mov ebx, eax
    
.merge_loop:
    ; Check if current block is free
    cmp dword [ebx + 4], 0
    jne .done
    
    ; Find next block
    mov ecx, [ebx]          ; Current block size
    mov edx, ebx
    add edx, ecx
    add edx, ALLOC_HEADER_SIZE  ; Next block
    
    ; Check if next block is within heap
    cmp edx, [heap_end]
    jae .done
    
    ; Check if next block is free
    cmp dword [edx + 4], 0
    jne .done
    
    ; Merge blocks
    mov eax, [edx]          ; Next block size
    add eax, ALLOC_HEADER_SIZE
    add [ebx], eax          ; Add to current block size
    
    ; Continue merging
    jmp .merge_loop

.done:
    pop edx
    pop ecx
    pop ebx
    ret

garbage_collect:
    ; Simple mark-and-sweep garbage collector
    push eax
    push ebx
    push ecx
    
    ; Mark phase: mark all reachable objects
    call mark_reachable_objects
    
    ; Sweep phase: free all unmarked objects
    call sweep_unmarked_objects
    
    ; Merge free blocks
    mov eax, [heap_start]
    call merge_free_blocks
    
    pop ecx
    pop ebx
    pop eax
    ret

mark_reachable_objects:
    ; Mark all objects reachable from global variables
    ; TODO: Implement proper marking based on variable references
    push eax
    push ebx
    
    ; For now, just mark all used blocks as reachable
    ; A real implementation would traverse from roots
    
    pop ebx
    pop eax
    ret

sweep_unmarked_objects:
    ; Free all objects not marked as reachable
    push eax
    push ebx
    
    mov eax, [heap_start]
    
.sweep_loop:
    cmp eax, [heap_end]
    jae .done
    
    ; Check if block is used but not marked
    ; For this simple version, we don't actually sweep
    ; A real implementation would check mark bits
    
    ; Move to next block
    mov ebx, [eax]          ; Block size
    add eax, ebx
    add eax, ALLOC_HEADER_SIZE
    jmp .sweep_loop

.done:
    pop ebx
    pop eax
    ret

system_malloc:
    ; System-level malloc using brk
    ; EAX = size
    ; Returns pointer in EAX
    push ebx
    push ecx
    
    ; Get current program break
    mov ebx, 0
    mov eax, 45             ; sys_brk
    int 0x80
    mov ebx, eax            ; Save current break
    
    ; Calculate new break
    add eax, [esp + 8]      ; Add requested size
    push ebx                ; Save old break
    
    ; Set new break
    mov ebx, eax
    mov eax, 45             ; sys_brk
    int 0x80
    
    ; Return old break as allocated pointer
    pop eax
    
    pop ecx
    pop ebx
    ret

; Debug functions
dump_heap:
    ; Debug function to dump heap contents
    push eax
    push ebx
    push ecx
    
    mov eax, [heap_start]
    
.dump_loop:
    cmp eax, [heap_end]
    jae .done
    
    ; Print block info (would need printf-like function)
    ; For now, just a placeholder
    
    mov ebx, [eax]          ; Block size
    add eax, ebx
    add eax, ALLOC_HEADER_SIZE
    jmp .dump_loop

.done:
    pop ecx
    pop ebx
    pop eax
    ret
