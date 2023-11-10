proc drawField uses ecx edi ebx edx ebp esi
  mov eax, [FieldSize]
  mul [FieldSize]
  mov ecx, eax 
  mov edi, [FieldAddr]
  mov ebx, [XFieldOffset] ; X coords offset
  mov ebp, [YFieldOffset] ; Y coords offset 

  mov esi, [FoodAddr] ; will store current food addr (needed to get food amount quickly)
  mov edx, [AgentsAddr] ; will store current agent addr
  .GoThoughFieldCells:
    mov eax, EMPTY_COLOR ; storing there color
    test byte[edi], FIELD_AGENT_STATE
    jz @F
    ; backing up esi
    push esi 
    mov esi, edx
    movzx eax, word[esi + AGENT_ENERGY_OFFSET]
    pop esi
    
    stdcall CalcAgentColor, eax
    add edx, [AgentRecSize]
    jmp .stopColorSelection
    @@:
    test byte[edi], FIELD_FOOD_STATE
    jz .stopColorSelection
    
    movzx eax, word[esi + FOOD_AMOUNT_OFFSET]
    stdcall CalcFoodColor, eax

    add esi, [FoodRecSize]
    .stopColorSelection:
    stdcall DrawRect, [ScreenBufAddr], ebx, ebp, [CellSizePX], [CellSizePX], eax

    add ebx, [CellSizePX]
    mov eax, [ScreenWidth]
    sub eax, [XFieldOffset]
    dec eax
    cmp ebx, eax
    jb @F

    .NextLine:
      add ebp, [CellSizePX]
      mov ebx, [XFieldOffset]
    @@:
    inc edi
  loop .GoThoughFieldCells
  invoke SetDIBitsToDevice, [hDC], 0, 0, [ScreenWidth], [ScreenHeight], 0, 0, 0, [ScreenHeight], [ScreenBufAddr], bmi, 0
  ret 
endp

proc BufMoveAgent uses ecx edi edx ebx, src, dest, energy
  local X dd ?
  local Y dd ?

  mov eax, [src]
  xor edx, edx
  div [FieldSize]
  mov [X], edx 
  mov [Y], eax

  ; getting cell Y coord in pxs
  mov eax, [Y]
  mul [CellSizePX]
  add eax, [YFieldOffset]
  mov [Y], eax
  mul [ScreenWidth]
  mov ebx, eax

  mov eax, [X]
  mul [CellSizePX]
  add eax, [XFieldOffset]
  mov [X], eax


  add ebx, eax

  mul [ScreenWidth]
  mov edi, [ScreenBufAddr]
  stdcall CalcAgentColor, [energy]
  mov ecx, eax ; saving old cell color

  stdcall DrawRect, [ScreenBufAddr], [X], [Y], [CellSizePX], [CellSizePX], EMPTY_COLOR
  
  mov eax, [dest]
  xor edx, edx
  div [FieldSize]
  mov [X], edx 
  mov [Y], eax

  ; getting cell Y coord in pxs
  mov eax, [Y]
  mul [CellSizePX]
  add eax, [YFieldOffset]
  mov [Y], eax

  mov eax, [X]
  mul [CellSizePX]
  add eax, [XFieldOffset]
  stdcall DrawRect, [ScreenBufAddr], eax, [Y], [CellSizePX], [CellSizePX], ecx

  ret
endp

proc BufCloneCell uses ecx edi edx, src, dest, energy
  local X dd ?
  local Y dd ?

  mov eax, [src]
  xor edx, edx
  div [FieldSize]
  mov [X], edx 
  mov [Y], eax

  ; getting cell Y coord in pxs
  mov eax, [Y]
  mul [CellSizePX]
  add eax, [YFieldOffset]
  mov [Y], eax
  mul [ScreenWidth]
  mov ebx, eax

  mov eax, [X]
  mul [CellSizePX]
  add ebx, eax
  add ebx, [XFieldOffset]
  
  mov edi, [ScreenBufAddr]
  stdcall CalcAgentColor, [energy]
  mov ebx, eax ; getting old cell color

  mov eax, [dest]
  xor edx, edx
  div [FieldSize]
  mov [X], edx 
  mov [Y], eax

  ; getting cell Y coord in pxs
  mov eax, [Y]
  mul [CellSizePX]
  add eax, [YFieldOffset]
  mov [Y], eax

  mov eax, [X]
  mul [CellSizePX]
  add eax, [XFieldOffset]
  stdcall DrawRect, [ScreenBufAddr], eax, [Y], [CellSizePX], [CellSizePX], ebx

  ret
endp

proc bufClearCell uses ecx edi edx ebx, src
  local X dd ?
  local Y dd ?

  mov eax, [src]
  xor edx, edx
  div [FieldSize]
  mov [X], edx 
  mov [Y], eax

  ; getting cell Y coord in pxs
  mov eax, [Y]
  mul [CellSizePX]
  add eax, [YFieldOffset]
  mov [Y], eax

  mov eax, [X]
  mul [CellSizePX]
  add eax, [XFieldOffset]

  stdcall DrawRect, [ScreenBufAddr], eax, [Y], [CellSizePX], [CellSizePX], EMPTY_COLOR
  ret
endp

proc bufUpdateCellColor uses ecx edi edx ebx, src, color
  local X dd ?
  local Y dd ?

  mov eax, [src]
  xor edx, edx
  div [FieldSize]
  mov [X], edx 
  mov [Y], eax

  mov eax, [Y]
  mul [CellSizePX]
  add eax, [YFieldOffset]
  mov [Y], eax

  mov eax, [X]
  mul [CellSizePX]
  add eax, [XFieldOffset]
  mov ebx, [color]
  stdcall DrawRect, [ScreenBufAddr], eax, [Y], [CellSizePX], [CellSizePX], ebx
  ret
endp

proc calcCellSize
  ; assuming that height is less then width
  mov eax, [ScreenHeight] 
  sub eax, 2
  xor edx, edx
  div [FieldSize]

  cmp eax, 0
  je .LessThen1PX
  mov [CellSizePX], eax
  jmp .Finished
  .LessThen1PX:
    mov [CellSizePX], 1
    mov eax, [ScreenHeight]
    mov [FieldSize], eax
    ; NEEDS TO BE DONE
  .Finished:

  ret
endp

proc calcFieldOffsets
  mov ebx, [ScreenHeight]
  
  ; getting size of field in pixels
  mov eax, [FieldSize]
  mul [CellSizePX]

  ; calculating left space on screen in Y axis
  sub ebx, eax
  shr ebx, 1
  dec eax
  mov [YFieldOffset], ebx

  ; same for X-axis
  mov ebx, [ScreenWidth]
  sub ebx, eax
  shr ebx, 1
  mov [XFieldOffset], ebx

  ret
endp


proc CalcAgentColor uses edx ebx ecx, energy 
    movzx eax, word[energy]
    xor edx, edx

    ; considering AgentMinEnergyToClone as max energy
    mov ecx, 0xFF
    mul ecx
    xor edx, edx
    mov ecx, [AgentMinEnergyToClone]
    div ecx
    shl eax, 16
  ret
endp

proc CalcFoodColor uses edx ebx ecx, amount 
    movzx eax, word[amount]
    xor edx, edx

    ; considering AgentMinEnergyToClone as max energy
    mov ecx, 0xFF
    mul ecx
    xor edx, edx
    mov ecx, [FoodMaxValue]
    div ecx
  ret
endp


; x, y - in pixels 
proc DrawRect uses eax ebx edx ecx edi, buffer, x, y, height, width, color
  mov ecx, [height]
  mov eax, [ScreenWidth]
  shl eax, 2
  mul [y]
  mov edi, [buffer]
  add edi, eax
  mov eax, [x]
  shl eax, 2
  add edi, eax
  
  mov edx, eax ; backed up
  mov eax, [color]
  rectangleLoop:
      push ecx

          mov ecx, [width]

          
          rep stosd
          mov ebx, [width]
          shl ebx, 2
          sub edi, ebx
          mov ebx, [ScreenWidth]
          shl ebx, 2
          add edi, ebx
      pop ecx
  loop rectangleLoop
  ret 
endp

proc drawBkg
  mov edi, [ScreenBufAddr]
  mov eax, [ScreenWidth]
  mul [ScreenHeight]
  mov ecx, eax
  mov eax, 0xFFFFFFFF
  rep stosd
  ret
endp

proc GUIBasicInit

  ; getting screen X size and Y
  invoke GetSystemMetrics, SM_CXSCREEN
  mov [ScreenWidth], eax

  invoke GetSystemMetrics, SM_CYSCREEN
  mov [ScreenHeight], eax

  invoke GetModuleHandle, 0
  mov [wc.hInstance], eax
  invoke LoadIcon, 0, IDI_APPLICATION
  mov [wc.hIcon], eax
  invoke LoadCursor, 0, IDC_ARROW
  mov [wc.hCursor], eax
  invoke RegisterClass, wc
  test eax, eax
  jz error

  invoke CreateWindowEx, 0, _class, 0, WS_VISIBLE + WS_POPUP, 0, 0, [ScreenWidth], [ScreenHeight], NULL, NULL, [wc.hInstance], NULL
  
  mov [hwnd], eax
  invoke GetDC, [hwnd]
  mov [hDC], eax
  mov [bmi.biSize], sizeof.BITMAPINFOHEADER
  mov eax, [ScreenWidth]
  mov [bmi.biWidth], eax
  mov eax, [ScreenHeight]
  mov [bmi.biHeight], eax
  mov [bmi.biPlanes], 1
  mov [bmi.biBitCount], 32
  mov [bmi.biCompression], BI_RGB

  jmp @F
  error:
    invoke MessageBox, NULL, _error, NULL, MB_ICONERROR + MB_OK

  @@:
  ret 
endp

proc ProcessWindowMsgs
  invoke PeekMessage, msg, NULL, 0, 0, 1 
  ; cmp eax, 1
  ; je @F

  cmp eax, 0
  jne @F 
    jmp .finish 
  
  @@:
  invoke TranslateMessage, msg
  invoke DispatchMessage, msg

  .finish:
  ret 
endp

proc WindowProc uses ebx esi edi, hwnd, wmsg, wparam, lparam
  cmp [wmsg], WM_DESTROY
  je .wmdestroy
  .defwndproc:
  invoke DefWindowProc, [hwnd], [wmsg], [wparam], [lparam]
  jmp .finish
  .wmdestroy:
  invoke PostQuitMessage, 0
  xor eax, eax
  .finish:
  ret
endp