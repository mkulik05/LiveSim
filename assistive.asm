
; eax - return new rand value up to maxVal
proc RandInt uses ecx ebx edx, maxVal 
    xor eax, eax
    rdrand ax
    mul word[maxVal]
    mov ebx, eax
    movzx eax, dx
    shl eax, 16
    add eax, ebx
    ; in eax - value * NewMax

    xor edx, edx
    mov ecx, 0x00_00_FF_FF 
    div ecx
    ret 
endp

proc getFieldSize, size
  mov eax, [size]
  mul eax
  mul [fieldCellSize]
  ret
endp

; Allocate required amount of memory (memSize) for field. Stores heapHandle in HeapHandle
proc allocMem uses esi edx, memSize, PHeapHandle, PbufAddr
  ; getting heap addr
  invoke GetProcessHeap
  mov esi, [PHeapHandle] ; got addr of HeapHandle
  mov [esi], eax
  ; alloc memory for field
  invoke HeapAlloc, eax, 0, [memSize]
  mov esi, [PbufAddr] ; got addr of buf addr
  mov [esi], eax
  
  ; if ax is zero -- allocation failed
  test eax, eax
  jz .alloc_failed
  jmp .done

; displaying error msg, shutting down
.alloc_failed:
  invoke MessageBox, 0, allocFailedMsg, allocFailedMsg, MB_OK
  invoke ExitProcess, 0
  
.done:
  ret
endp


proc removeVecItem uses esi edi ecx ebp ebx, Addr, PSize, ItemSize, CoordsOffset, ind
    mov edi, [Addr]
    mov eax, [ind]
    mul dword[ItemSize] 
    add edi, eax ; got delete agent addr

    mov ebx, [CoordsOffset]
    mov esi, [edi + ebx] ; coords of item
    mov ebx, [fieldAddr]

    ; NEED TO BE FIXED IN THE FUTURE
    mov byte[ebx + esi], 0 ; clear game field
    
    mov eax, [PSize]
    mov eax, [eax]
    cmp eax, 1
    jne @F
      jmp finished
    @@:
    dec eax ; cause indexes from zero
    cmp eax, [ind]
    jne @F
      jmp finished
    @@:
      mov esi, [Addr]
      mov eax, [PSize]
      mov eax, [eax]
      dec eax ; got index
      mul dword[ItemSize] 
      add esi, eax
      
      mov ecx, [ItemSize]
      rep movsb ; write last agent info into whole after removed agent

    finished:
      mov esi, [PSize]
      dec dword[esi]
  ret
endp