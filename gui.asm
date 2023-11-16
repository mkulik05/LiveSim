proc drawField uses ecx edi ebx edx ebp esi
  mov eax, [FieldSize]
  mul [FieldSize]
  mov ecx, eax 
  mov edi, [FieldAddr]
  mov ebx, [XFieldOffset] ; X coords offset
  mov ebp, [YFieldOffset] ; Y coords offset 

  ; mov esi, [FoodAddr] ; will store current food addr (needed to get food amount quickly)
  ; mov edx, [AgentsAddr] ; will store current agent addr
  .GoThoughFieldCells:
    mov eax, EMPTY_COLOR ; storing there color
    test dword[edi], FIELD_AGENT_STATE
    jz @F

    mov eax, dword[edi]
    and eax, FIELD_SAFE_MASK
    mov esi, [AgentsAddr]
    mul [AgentRecSize]
    add esi, eax
    movzx eax, word[esi + AGENT_ENERGY_OFFSET]
    
    stdcall CalcAgentColor, eax
    add edx, [AgentRecSize]
    jmp .stopColorSelection
    @@:
    test dword[edi], FIELD_FOOD_STATE
    jz .stopColorSelection
    
    mov eax, dword[edi]
    and eax, FIELD_SAFE_MASK
    mov esi, [FoodAddr]
    mul [FoodRecSize]
    add esi, eax
    movzx eax, word[esi + FOOD_AMOUNT_OFFSET]
    stdcall CalcFoodColor, eax

    .stopColorSelection:
    stdcall DrawRect, [ScreenBufAddr], ebx, ebp, [CellSizePX], [CellSizePX], eax

    add ebx, [CellSizePX]
    mov eax, [FieldWidth]
    sub eax, [XFieldOffset]
    dec eax
    cmp ebx, eax
    jb @F

    .NextLine:
      add ebp, [CellSizePX]
      mov ebx, [XFieldOffset]
    @@:
    add edi, FieldCellSize
  dec ecx 
  cmp ecx, 0 
  ja .GoThoughFieldCells

  invoke SetDIBitsToDevice, [hDC], [FieldXOffset], [FieldYOffset], [FieldWidth], [FieldHeight], 0, 0, 0, [FieldHeight], [ScreenBufAddr], bmi, 0
  ret 
endp

proc PrintStats 
  local rect RECT

  ; tact number
  stdcall IntToStr, [TotalTacts], tactNStr, tactNStrStartI ; Assuming tactNStrStartI is the starting index for the number in tactNStr
  mov [rect.left], TEXT_MARGIN_LEFT
  mov eax, [FieldXOffset]
  mov [rect.right], eax
  mov [rect.top], TEXT_MARGIN_TOP
  mov [rect.bottom], TEXT_FONT_SIZE * 2
  lea eax, [rect] 
  invoke FillRect, [hDC], eax, [bkgBrush]
  lea eax, [rect] 
  invoke DrawText, [hDC], tactNStr, -1, eax, DT_LEFT

  stdcall IntToStr, [AgentsSize], agentsNStr, agentsNStrStartI ; Assuming tactNStrStartI is the starting index for the number in tactNStr
  mov [rect.left], TEXT_MARGIN_LEFT
  mov eax, [FieldXOffset]
  mov [rect.right], eax
  
  mov [rect.top], TEXT_FONT_SIZE * 2 + TEXT_MARGIN_TOP
  mov [rect.bottom], TEXT_FONT_SIZE * 2 + TEXT_MARGIN_TOP + TEXT_FONT_SIZE * 2
  lea eax, [rect] 
  invoke FillRect, [hDC], eax, [bkgBrush]
  lea eax, [rect]
  invoke DrawText, [hDC], agentsNStr, -1, eax, DT_LEFT

  stdcall IntToStr, [FoodSize], foodNStr, foodNStrStartI ; Assuming tactNStrStartI is the starting index for the number in tactNStr
  mov [rect.left], TEXT_MARGIN_LEFT
  mov eax, [FieldXOffset]
  mov [rect.right], eax
  
  mov [rect.top], TEXT_FONT_SIZE * 2 + TEXT_MARGIN_TOP + TEXT_FONT_SIZE * 2
  mov [rect.bottom], TEXT_FONT_SIZE * 2 + TEXT_MARGIN_TOP + TEXT_FONT_SIZE * 2 + TEXT_FONT_SIZE * 2 
  lea eax, [rect] 
  invoke FillRect, [hDC], eax, [bkgBrush]
  lea eax, [rect]
  invoke DrawText, [hDC], foodNStr, -1, eax, DT_LEFT

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

proc BufCloneCell uses ecx, src, dest, energy
  stdcall CalcAgentColor, [energy]
  mov ecx, eax
  stdcall bufUpdateCellColor, [src], ecx
  stdcall bufUpdateCellColor, [dest], ecx
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
  mov eax, [FieldHeight] 
  sub eax, 2
  xor edx, edx
  div [FieldSize]

  cmp eax, 0
  je .LessThen1PX
  mov [CellSizePX], eax
  jmp .Finished
  .LessThen1PX:
    mov [CellSizePX], 1
    mov eax, [FieldHeight]
    mov [FieldSize], eax
    ; NEEDS TO BE DONE
  .Finished:

  ret
endp

proc calcFieldOffsets
  mov ebx, [FieldHeight]
  
  ; getting size of field in pixels
  mov eax, [FieldSize]
  mul [CellSizePX]

  ; calculating left space on screen in Y axis
  sub ebx, eax
  shr ebx, 1
  dec eax
  mov [YFieldOffset], ebx

  ; same for X-axis
  mov ebx, [FieldWidth]
  sub ebx, eax
  shr ebx, 1
  mov [XFieldOffset], ebx

  ret
endp

proc CalcAgentColor uses edx ebx ecx, energy 
    mov eax, [energy]
    xor edx, edx
    cmp eax, [AgentMinEnergyToClone]
    jb @F
      mov eax, [AgentMinEnergyToClone] 
      jmp .stop
      ; if energy if more then max value, putting max brightness
      ; such case mb after feeding, but before cloning (it's 2 tacts, but redrawing is each tact)
    @@:
    mov ecx, 0xFF
    mul ecx
    xor edx, edx
    mov ecx, [AgentMinEnergyToClone]
    div ecx
    shl eax, 16
    .stop:
  ret
endp

proc CalcFoodColor uses edx ebx ecx, amount 
    mov eax, [amount]
    cmp eax, [FoodMaxValue]
    jb @F
      mov eax, [FoodMaxValue] 
      jmp .stop
    @@:
    xor edx, edx
    mov ecx, 0xFF
    mul ecx
    xor edx, edx
    mov ecx, [FoodMaxValue]
    div ecx
    .stop:
  ret
endp


; x, y - in pixels 
proc DrawRect uses eax ebx edx ecx edi, buffer, x, y, height, width, color
  mov ecx, [height]
  mov eax, [FieldWidth]
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
          mov ebx, [FieldWidth]
          shl ebx, 2
          add edi, ebx
      pop ecx
  loop rectangleLoop
  ret 
endp

proc drawBkg
  local rect RECT
  mov edi, [ScreenBufAddr]
  mov eax, [FieldWidth]
  mul [FieldHeight]
  mov ecx, eax
  mov eax, GAME_BKG_COLOR
  rep stosd

  lea eax, [rect]
  invoke GetClientRect, [hwnd], eax
  lea eax, [rect]
  invoke FillRect, [hDC], eax, [bkgBrush]

  ret
endp

proc GUIBasicInit

  ; getting screen X size and Y
  invoke GetSystemMetrics, SM_CXSCREEN
  mov [ScreenWidth], eax
  mov [FieldXOffset], eax

  invoke GetSystemMetrics, SM_CYSCREEN
  mov [ScreenHeight], eax
  mov [FieldHeight], eax
  mov [FieldWidth], eax
  mov [FieldYOffset], 0

  sub [FieldXOffset], eax
  shr [FieldXOffset], 1


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
  mov eax, [FieldWidth]
  mov [bmi.biWidth], eax
  mov eax, [FieldHeight]
  mov [bmi.biHeight], eax
  mov [bmi.biPlanes], 1
  mov [bmi.biBitCount], 32
  mov [bmi.biCompression], BI_RGB

  ; setup font size
  mov [lf.lfHeight], TEXT_FONT_SIZE
  invoke CreateFontIndirect, lf
  invoke SelectObject, [hDC], eax

  ; create brush for text bkg (to clear old text)
  invoke CreateSolidBrush, GAME_BKG_COLOR
  mov [bkgBrush], eax

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
  cmp [wmsg], WM_KEYDOWN
  je .keyDown
  invoke DefWindowProc, [hwnd], [wmsg], [wparam], [lparam]
  jmp .finish

  .keyDown:
    cmp [wparam], VK_ESCAPE
    je .wmdestroy
    cmp [wparam], VK_SPACE
    jne .coninueAnalisis
    cmp [PauseGame], 0
    je @F 
    mov [PauseGame], 0
    jmp .finish
    @@:
    mov [PauseGame], 1
    .coninueAnalisis:
    ; 'n' key
    cmp [wparam], 0x4E
    jne @F
    mov [PutOnPauseNextTact], 1
    mov [PauseGame], 0

    @@:
    ; 's' key - save field 
    cmp [wparam], 0x53
    jne @F
    stdcall saveField, fname1

    @@:
    ; 'd' key - save configuration
    cmp [wparam], 0x44
    jne @F
    stdcall saveSettings, fname2

    @@:
    ; 'l' key - load configuration
    cmp [wparam], 0x4C
    jne @F
    stdcall loadSettings, fname2

    @@:
    ; 'k' key - load field
    cmp [wparam], 0x4B
    jne .finish 
    stdcall loadField, fname1
  jmp .finish

  .wmdestroy:
  invoke PostQuitMessage, 0
  xor eax, eax
  invoke  ExitProcess, 0
  .finish:
  ret
endp