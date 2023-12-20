proc calcMaxConsoleLines uses ebx edx
  ; not counting console input part
  mov eax, [ScreenHeight]
  sub eax, TEXT_FONT_SIZE * 2

  mov ebx, TEXT_FONT_SIZE * 2

  div ebx

  mov [ConsoleBufSavesN], eax

  ret
endp

; eax - return new rand value up to maxVal
proc RandInt uses ecx edx, maxVal 
    rdrand eax
    xor edx, edx
    mul [maxVal]
    mov ecx, 0xFF_FF_FF_FF 
    div ecx
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
    add edi, eax ; got delete agent addк

    ; clearing index from field cell (the one that is deleted)
    mov ebx, [CoordsOffset]
    mov eax, [edi + ebx] ; coords of item
    mov ebx, [FieldAddr]
    shl eax, 2
    add ebx, eax 
    ; and dword[ebx], 1100_0000_0000_0000_0000_0000_0000_0000b

    mov eax, [PSize]
    mov eax, [eax]
    cmp eax, 1
    jne @F
      jmp finished
    @@:

    dec eax ; cause indexes from zero
    push eax

    ; updating index of prev last element (that will be swapped with removed) in vector
    mul [ItemSize] 
    mov esi, [Addr]
    add esi, eax ; got addr of last element
    mov ebx, [CoordsOffset]
    mov eax, [esi + ebx] ; got last element coords
     
    mov esi, [FieldAddr]
    shl eax, 2
    add esi, eax 
    and dword[esi], 1100_0000_0000_0000_0000_0000_0000_0000b
    mov eax, [ind]
    or dword[esi], eax

    pop eax
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

proc IntToStr uses edx ebx edi esi ecx, num, buf
    mov ebx, 10
    mov eax, [num]
    mov esi, [buf]

    xor ecx, ecx
    .ConvertLoop:
        xor edx, edx
        div ebx
        add edx, '0'
        mov byte[esi], dl
        
        inc ecx
        inc esi

        cmp eax, 0
        
    jnz .ConvertLoop


    mov byte[esi], 0 ; zero terminated string 

    dec esi ; got last digit pos in string 
    mov edi, esi ; save last pos
    dec ecx
    sub esi, ecx ; got first digit pos in string
    .invertOrderLoop:
      cmp esi, edi 
      jge .stop

      mov al, byte[esi]
      mov ah, byte[edi]
      mov byte[esi], ah
      mov byte[edi], al

      inc esi 
      dec edi
      jmp .invertOrderLoop
      
    .stop:

  ret
endp