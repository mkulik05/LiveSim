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
    mov eax, [FieldZoneWidth]
    sub eax, [XFieldOffset]
    cmp ebx, eax
    jb @F

    .NextLine:
      add ebp, [CellSizePX]
      mov ebx, [XFieldOffset]
    @@:
    add edi, FIELD_CELL_SIZE
  dec ecx 
  cmp ecx, 0 
  ja .GoThoughFieldCells

  invoke SetDIBitsToDevice, [hBufDC], [FieldXInOffset], [FieldYInOffset], [FieldZoneWidth], [FieldZoneHeight], 0, 0, 0, [FieldZoneHeight], [ScreenBufAddr], bmi, 0
  ret 
endp

proc ShowHints
  local rect RECT

  push [lf.lfHeight]
  mov [lf.lfHeight], HINT_FONT_SIZE
  invoke CreateFontIndirect, lf
  invoke SelectObject, [hBufDC], eax

  mov [rect.left], TEXT_MARGIN_LEFT
  mov eax, [FieldXInOffset]
  mov [rect.right], eax
  mov eax, [ScreenHeight]
  sub eax, TEXT_MARGIN_TOP
  sub eax, HINT_FONT_SIZE * 3
  mov [rect.bottom], eax
  sub eax, HINT_FONT_SIZE * 5
  mov [rect.top], eax

  lea eax, [rect] 
  invoke DrawText, [hBufDC], Hint1, -1, eax, DT_LEFT
  cmp [InitedHint], 1
  je @F
  invoke BitBlt, [hMainDc], 0, 0, [ScreenWidth], [ScreenHeight], [hBufDC], 0, 0, SRCCOPY
  invoke Sleep, 200

  @@:
  add [rect.bottom], HINT_FONT_SIZE * 2
  add [rect.top], HINT_FONT_SIZE * 2
  lea eax, [rect] 
  invoke DrawText, [hBufDC], Hint2, -1, eax, DT_LEFT
  cmp [InitedHint], 1
  je @F
  invoke BitBlt, [hMainDc], 0, 0, [ScreenWidth], [ScreenHeight], [hBufDC], 0, 0, SRCCOPY
  invoke Sleep, 200

  @@:
  add [rect.bottom], HINT_FONT_SIZE * 2
  add [rect.top], HINT_FONT_SIZE * 2
  lea eax, [rect] 
  invoke DrawText, [hBufDC], Hint3, -1, eax, DT_LEFT

  cmp [InitedHint], 1
  je @F
  invoke BitBlt, [hMainDc], 0, 0, [ScreenWidth], [ScreenHeight], [hBufDC], 0, 0, SRCCOPY
  invoke Sleep, 200

  @@:
  add [rect.bottom], HINT_FONT_SIZE * 2
  add [rect.top], HINT_FONT_SIZE * 2
  lea eax, [rect] 
  invoke DrawText, [hBufDC], Hint4, -1, eax, DT_LEFT

  invoke BitBlt, [hMainDc], 0, 0, [ScreenWidth], [ScreenHeight], [hBufDC], 0, 0, SRCCOPY
  pop [lf.lfHeight]
  invoke CreateFontIndirect, lf
  invoke SelectObject, [hBufDC], eax

  mov [InitedHint], 1
  ret 
endp

proc PrintStats 
  local rect RECT

  ; tact number
  stdcall IntToStr, [TotalTacts], numStr ; Assuming tactNStrStartI is the starting index for the number in tactNStr
  mov [rect.left], TEXT_MARGIN_LEFT
  mov eax, [maxTextWidth]
  add [rect.left], eax
  mov eax, [FieldXInOffset]
  mov [rect.right], eax
  mov [rect.top], TEXT_MARGIN_TOP
  mov [rect.bottom], TEXT_FONT_SIZE * 2
  lea eax, [rect] 
  invoke FillRect, [hBufDC], eax, [bkgBrush]
  lea eax, [rect] 
  invoke DrawText, [hBufDC], numStr, -1, eax, DT_LEFT

  stdcall IntToStr, [AgentsSize], numStr ; Assuming tactNStrStartI is the starting index for the number in tactNStr
  mov [rect.left], TEXT_MARGIN_LEFT
  mov eax, [maxTextWidth]
  add [rect.left], eax
  mov eax, [FieldXInOffset]
  mov [rect.right], eax
  
  mov [rect.top], TEXT_FONT_SIZE * 2 + TEXT_MARGIN_TOP
  mov [rect.bottom], TEXT_FONT_SIZE * 2 + TEXT_MARGIN_TOP + TEXT_FONT_SIZE * 2
  lea eax, [rect] 
  invoke FillRect, [hBufDC], eax, [bkgBrush]
  lea eax, [rect]
  invoke DrawText, [hBufDC], numStr, -1, eax, DT_LEFT

  stdcall IntToStr, [FoodSize], numStr ; Assuming tactNStrStartI is the starting index for the number in tactNStr
  mov [rect.left], TEXT_MARGIN_LEFT
  mov eax, [maxTextWidth]
  add [rect.left], eax
  mov eax, [FieldXInOffset]
  mov [rect.right], eax
  
  mov [rect.top], TEXT_FONT_SIZE * 2 + TEXT_MARGIN_TOP + TEXT_FONT_SIZE * 2
  mov [rect.bottom], TEXT_FONT_SIZE * 2 + TEXT_MARGIN_TOP + TEXT_FONT_SIZE * 2 + TEXT_FONT_SIZE * 2 
  lea eax, [rect] 
  invoke FillRect, [hBufDC], eax, [bkgBrush]
  lea eax, [rect]
  invoke DrawText, [hBufDC], numStr, -1, eax, DT_LEFT

  ret 
endp

proc BufMoveAgent uses ecx edi edx ebx, src, dest, energy
  stdcall CalcAgentColor, [energy]
  mov ecx, eax
  stdcall bufUpdateCellColor, [src], EMPTY_COLOR
  stdcall bufUpdateCellColor, [dest], ecx
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
  stdcall bufUpdateCellColor, [src], EMPTY_COLOR
  ret
endp

proc bufUpdateCellColor uses ecx edi edx ebx, src, color
  local screenX dd ?
  local screenY dd ?

  mov eax, [src]
  xor edx, edx
  div [FieldSize]
  mov [screenX], edx 
  mov [screenY], eax

  mov eax, [screenY]
  mul [CellSizePX]
  add eax, [YFieldOffset]
  mov [screenY], eax

  mov eax, [screenX]
  mul [CellSizePX]
  add eax, [XFieldOffset]
  mov ebx, [color]
  stdcall DrawRect, [ScreenBufAddr], eax, [screenY], [CellSizePX], [CellSizePX], ebx
  ret
endp

proc calcCellSize
  ; assuming that height is less then width
  mov eax, [FieldZoneHeight] 
  sub eax, 2
  xor edx, edx
  div [FieldSize]

  cmp eax, 0
  je .LessThen1PX
  mov [CellSizePX], eax
  jmp .Finished
  .LessThen1PX:
    mov [CellSizePX], 1
    mov eax, [FieldZoneHeight]
    mov [FieldSize], eax
    ; NEEDS TO BE DONE
  .Finished:

  ret
endp

proc calcLeftTextOffset
  local sizee SIZE
  local rect RECT
  ; calculating offsets 
  lea eax, [sizee]
  invoke GetTextExtentPoint32, [hBufDC], tactNStr, tactNStrLen, eax

  mov eax, [sizee.cx]
  mov [maxTextWidth], eax

  lea eax, [sizee]
  invoke GetTextExtentPoint32, [hBufDC], agentsNStr, agentsNStrLen, eax 

  mov eax, [sizee.cx]
  cmp eax, [maxTextWidth]
  jb @F 
    mov [maxTextWidth], eax
  @@:

  lea eax, [sizee]
  invoke GetTextExtentPoint32, [hBufDC], foodNStr, foodNStrLen, eax 

  mov eax, [sizee.cx]
  cmp eax, [maxTextWidth]
  jb @F 
    mov [maxTextWidth], eax
  @@:
  

  mov [rect.left], TEXT_MARGIN_LEFT * 2
  mov eax, [FieldXInOffset]
  mov [rect.right], eax
  mov [rect.top], TEXT_MARGIN_TOP
  mov [rect.bottom], TEXT_FONT_SIZE * 2
  lea eax, [rect] 
  invoke FillRect, [hBufDC], eax, [bkgBrush]
  lea eax, [rect] 
  invoke DrawText, [hBufDC], tactNStr, tactNStrLen, eax, DT_LEFT

  mov [rect.top], TEXT_FONT_SIZE * 2 + TEXT_MARGIN_TOP
  mov [rect.bottom], TEXT_FONT_SIZE * 2 + TEXT_MARGIN_TOP + TEXT_FONT_SIZE * 2
  lea eax, [rect] 
  invoke FillRect, [hBufDC], eax, [bkgBrush]
  lea eax, [rect]
  invoke DrawText, [hBufDC], agentsNStr, agentsNStrLen, eax, DT_LEFT

  mov [rect.top], TEXT_FONT_SIZE * 2 + TEXT_MARGIN_TOP + TEXT_FONT_SIZE * 2
  mov [rect.bottom], TEXT_FONT_SIZE * 2 + TEXT_MARGIN_TOP + TEXT_FONT_SIZE * 2 + TEXT_FONT_SIZE * 2 
  lea eax, [rect] 
  invoke FillRect, [hBufDC], eax, [bkgBrush]
  lea eax, [rect]
  invoke DrawText, [hBufDC], foodNStr, foodNStrLen, eax, DT_LEFT
  ret 
endp 

proc calcFieldOffsets
  mov ebx, [FieldZoneHeight]
  
  ; getting size of field in pixels
  mov eax, [FieldSize]
  mul [CellSizePX]

  ; calculating left space on screen in Y axis
  sub ebx, eax
  shr ebx, 1
  dec eax
  mov [YFieldOffset], ebx

  ; same for X-axis
  mov ebx, [FieldZoneWidth]
  sub ebx, eax
  shr ebx, 1
  mov [XFieldOffset], ebx

  ret
endp

proc CalcAgentColor uses edx ebx ecx, energy 
    mov eax, [energy]
    cmp eax, [AgentMinEnergyToClone]
    jb @F
      mov eax, 0xFF ; color
      jmp .stop
      ; if energy if more then max value, putting max brightness
      ; such case mb after feeding, but before cloning (it's 2 tacts, but redrawing is each tact)
    @@:
    mov ecx, 0xFF
    mul ecx
    xor edx, edx
    mov ecx, [AgentMinEnergyToClone]
    div ecx

    ; setting min brightness (so agent will be at least visible)
    cmp eax, 0x20
    jg .stop 
    mov eax, 0x20
    .stop:
    shl eax, 16
  ret
endp

proc CalcFoodColor uses edx ebx ecx, amount 
    mov eax, [amount]
    cmp eax, [FoodMaxValue]
    jb @F
      mov eax, 0xFF ; color
      jmp .stop
    @@:
    xor edx, edx
    mov ecx, 0xFF
    mul ecx
    xor edx, edx
    mov ecx, [FoodMaxValue]
    div ecx

    cmp eax, 0x20
    jg .stop 
    mov eax, 0x20
    .stop:
  ret
endp


; x, y - in pixels 
proc DrawRect uses eax ebx edx ecx edi, buffer, x, y, height, width, color
  mov ecx, [height]
  mov eax, [FieldZoneWidth]
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
          mov ebx, [FieldZoneWidth]
          shl ebx, 2
          add edi, ebx
      pop ecx
  loop rectangleLoop
  ret 
endp

proc drawBkg
  local rect RECT
  mov edi, [ScreenBufAddr]
  mov eax, [FieldZoneWidth]
  mul [FieldZoneHeight]
  mov ecx, eax
  mov eax, GAME_BKG_COLOR
  rep stosd

  lea eax, [rect]
  invoke GetClientRect, [hwnd], eax
  lea eax, [rect]
  invoke FillRect, [hBufDC], eax, [bkgBrush]

  ret
endp

proc GUIBasicInit
  local sizee SIZE 
  local rect RECT

  ; getting screen X size and Y
  invoke GetSystemMetrics, SM_CXSCREEN
  mov [ScreenWidth], eax
  mov [FieldXInOffset], eax

  invoke GetSystemMetrics, SM_CYSCREEN
  mov [ScreenHeight], eax
  mov [FieldZoneHeight], eax
  mov [FieldZoneWidth], eax
  mov [FieldYInOffset], 0

  sub [FieldXInOffset], eax
  shr [FieldXInOffset], 1


  invoke GetModuleHandle, 0
  mov [wc.hInstance], eax
  invoke LoadIcon, 0, IDI_APPLICATION
  mov [wc.hIcon], eax
  invoke LoadCursor, 0, IDC_CROSS
  mov [wc.hCursor], eax
  invoke RegisterClass, wc
  test eax, eax
  jz error

  invoke CreateWindowEx, 0, _class, 0, WS_VISIBLE + WS_POPUP, 0, 0, [ScreenWidth], [ScreenHeight], NULL, NULL, [wc.hInstance], NULL
  
  mov [hwnd], eax
  invoke GetDC, [hwnd]
  mov [hMainDc], eax
  invoke CreateCompatibleDC, [hMainDc] 
  mov [hBufDC], eax 
  invoke CreateCompatibleBitmap, [hMainDc], [ScreenWidth], [ScreenHeight]
  invoke SelectObject, [hBufDC], eax

  mov [bmi.biSize], sizeof.BITMAPINFOHEADER
  mov eax, [FieldZoneWidth]
  mov [bmi.biWidth], eax
  mov eax, [FieldZoneHeight]
  mov [bmi.biHeight], eax
  mov [bmi.biPlanes], 1
  mov [bmi.biBitCount], 32
  mov [bmi.biCompression], BI_RGB

  ; setup font size
  mov [lf.lfHeight], TEXT_FONT_SIZE
  invoke CreateFontIndirect, lf
  invoke SelectObject, [hBufDC], eax

  ; create brush for text bkg (to clear old text)
  invoke CreateSolidBrush, GAME_BKG_COLOR
  mov [bkgBrush], eax

  invoke CreateSolidBrush, 0
  mov [blackBrush], eax

  ; cursor is like semaphore - twice hidden, twice should be shown
  cmp [isCursorShown], 1
  jne @F
  invoke ShowCursor, FALSE
  mov [isCursorShown], 0
  @@:

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


proc WriteMsg uses edi esi ebx, Msg
  local rect RECT

  push [lf.lfHeight]
  mov [lf.lfHeight], TEXT_CHAT_FONT_SIZE
  invoke CreateFontIndirect, lf
  invoke SelectObject, [hBufDC], eax
  ; initing them in the start, cause they are constant
  mov eax, [FieldXInOffset]
  add eax, [FieldZoneWidth] 
  mov [rect.left], eax
  add [rect.left], TEXT_MARGIN_LEFT / 2
  mov eax, [ScreenWidth]
  mov [rect.right], eax

  inc [ConsoleBufCurrSave]
  mov eax, [ConsoleBufSavesN]
  cmp dword[ConsoleBufCurrSave], eax
  jae .needRewrite

  ; saving text to corresponding slot (so history will work (in future:)))
  mov ecx, ConsoleBufSize + 1
  mov ebx, [ConsoleBufCurrSave]
  mov edi, [ConsoleBufSaves + ebx * 4]
  mov esi, [Msg]
  rep movsb

  mov eax, TEXT_FONT_SIZE * 2
  mul [ConsoleBufCurrSave]
  cmp [ConsoleBufCurrSave], 0
  jne @F 
    mov eax, TEXT_MARGIN_TOP
  @@:
  mov [rect.top], eax
  mov [rect.bottom], eax
  add [rect.bottom], TEXT_FONT_SIZE * 2

  lea eax, [rect] 
  invoke FillRect, [hBufDC], eax, [bkgBrush] 
  
  mov esi, [ConsoleBufCurrSave] 
  mov eax, [IsCommandValid]
  mov [ConsoleBufIsCorrect + esi * 4], eax
  cmp [ConsoleBufIsCorrect + esi * 4], 1
  je @F

    invoke SetTextColor, [hBufDC], INVALID_COMMAND_COLOR
    lea eax, [rect] 
    invoke DrawText, [hBufDC], [Msg], -1, eax, DT_LEFT
    invoke SetTextColor, [hBufDC], 0
    jmp .stop
  @@: 
  lea eax, [rect] 
  invoke DrawText, [hBufDC], [Msg], -1, eax, DT_LEFT

  jmp .stop

  .needRewrite:    
    ; backing up first cell (moving it into last one)
    mov edx, [ConsoleBufSaves]
    push edx

    ; starting shifting text in ConsoleBufSaves array
    mov ecx, [ConsoleBufSavesN]
    dec ecx
    mov ebx, 1
    mov [rect.top], TEXT_MARGIN_TOP
    mov [rect.bottom], TEXT_MARGIN_TOP + TEXT_FONT_SIZE * 2

    .shiftText:
      push ecx
      mov edx, [ConsoleBufSaves + ebx * 4]
      mov [ConsoleBufSaves + (ebx - 1) * 4], edx
      mov edx, [ConsoleBufIsCorrect + ebx * 4]
      mov [ConsoleBufIsCorrect + (ebx - 1) * 4], edx
      lea eax, [rect] 
      invoke FillRect, [hBufDC], eax, [bkgBrush]
      
      cmp [ConsoleBufIsCorrect + (ebx - 1) * 4], 1
      je @F
        invoke SetTextColor, [hBufDC], INVALID_COMMAND_COLOR
        lea eax, [rect] 
        invoke DrawText, [hBufDC], [ConsoleBufSaves + (ebx - 1) * 4], -1, eax, DT_LEFT
        invoke SetTextColor, [hBufDC], 0
        jmp .continue
      @@: 
      lea eax, [rect] 
      invoke DrawText, [hBufDC], [ConsoleBufSaves + (ebx - 1) * 4], -1, eax, DT_LEFT
      .continue:

      add [rect.top], TEXT_FONT_SIZE * 2
      add [rect.bottom], TEXT_FONT_SIZE * 2
      pop ecx
      inc ebx
    dec ecx
    cmp ecx, 0
    jne  .shiftText

    mov ebx, [ConsoleBufSavesN]
    mov eax, [IsCommandValid]
    mov [ConsoleBufIsCorrect + (ebx - 1) * 4], eax
    pop edx 
    mov [ConsoleBufSaves + (ebx - 1) * 4], edx

    ; saving text to corresponding slot (so history will work (in future:)))
    mov ecx, ConsoleBufSize + 1
    mov edi, [ConsoleBufSaves + (ebx - 1) * 4]
    mov esi, [Msg]
    rep movsb

    lea eax, [rect] 
    invoke FillRect, [hBufDC], eax, [bkgBrush]

    cmp [ConsoleBufIsCorrect + (ebx - 1) * 4], 1
    je @F

      invoke SetTextColor, [hBufDC], INVALID_COMMAND_COLOR
      lea eax, [rect] 
      invoke DrawText, [hBufDC], [ConsoleBufSaves + (ebx - 1) * 4], -1, eax, DT_LEFT
      invoke SetTextColor, [hBufDC], 0
      jmp .stop
    @@: 
    lea eax, [rect] 
    invoke DrawText, [hBufDC], [ConsoleBufSaves + (ebx - 1) * 4], -1, eax, DT_LEFT
  .stop:
  invoke BitBlt, [hMainDc], 0, 0, [ScreenWidth], [ScreenHeight], [hBufDC], 0, 0, SRCCOPY
  pop [lf.lfHeight]
  invoke CreateFontIndirect, lf
  invoke SelectObject, [hBufDC], eax
  ret 
endp

proc DrawCursor uses edi eax
  local rect RECT

  mov eax, [FieldXInOffset]
  add eax, [FieldZoneWidth] 
  mov [rect.left], eax
  add [rect.left], TEXT_MARGIN_LEFT / 2
  mov eax, [ScreenWidth]
  mov [rect.right], eax

  mov eax, [ScreenHeight]
  mov [rect.bottom], eax
  sub eax, TEXT_FONT_SIZE * 2
  mov [rect.top], eax
  lea eax, [rect] 
  invoke FillRect, [hBufDC], eax, [bkgBrush]
  lea eax, [rect] 
  invoke DrawText, [hBufDC], ConsoleActiveText, -1, eax, DT_LEFT
  invoke BitBlt, [hMainDc], 0, 0, [ScreenWidth], [ScreenHeight], [hBufDC], 0, 0, SRCCOPY
  ret 
endp

proc RedrawCommand uses edi eax
  local rect RECT
  mov edi, ConsoleInpBuf 
  add edi, [ConsoleCharsN]
  mov byte[edi], 0

 
  mov eax, [FieldXInOffset]
  mov [rect.left], eax
  mov eax, [FieldZoneWidth] 
  add [rect.left], eax
  add [rect.left], TEXT_MARGIN_LEFT / 2
  mov eax, [ScreenWidth]
  mov [rect.right], eax

  mov eax, [ScreenHeight]
  mov [rect.bottom], eax
  sub eax, TEXT_FONT_SIZE * 2
  mov [rect.top], eax
  lea eax, [rect] 
  invoke FillRect, [hBufDC], eax, [bkgBrush]
  lea eax, [rect] 
  invoke DrawText, [hBufDC], ConsoleInpBuf, -1, eax, DT_LEFT
  invoke BitBlt, [hMainDc], 0, 0, [ScreenWidth], [ScreenHeight], [hBufDC], 0, 0, SRCCOPY
  .stop:
  ret 
endp

proc WindowProc uses ebx esi edi, hwnd, wmsg, wparam, lparam
  cmp [wmsg], WM_DESTROY
  je .wmdestroy
  cmp [wmsg], WM_KEYDOWN
  je .checkInpMode 

  cmp [isDrawingActive], 1
  jne @F
  cmp [wmsg], WM_LBUTTONUP 
  je .MouseClickHandle
  ; cmp [wmsg], WM_SETCURSOR
  ; je .wmSetCursor
  cmp [wmsg], WM_MOUSEMOVE  
  jne @F 

  test [wparam], MK_LBUTTON
  jnz .MouseClickHandle ; left button is pressed

  @@:
  invoke DefWindowProc, [hwnd], [wmsg], [wparam], [lparam]
  jmp .full_skip
  
  .checkInpMode:
  cmp [ConsoleInputMode], 1
  jne .keyDown
  mov eax, [lparam]
  shr eax, 31 
  jc .full_skip



  .keyDown:
    cmp [HelpIsActive], 1

    jne @F 
      ; q
      cmp [wparam], 0x51
      jne .full_skip 
        stdcall ShowHints
        stdcall calcLeftTextOffset
        stdcall PrintStats
        invoke SetDIBitsToDevice, [hBufDC], [FieldXInOffset], [FieldYInOffset], [FieldZoneWidth], [FieldZoneHeight], 0, 0, 0, [FieldZoneHeight], [ScreenBufAddr], bmi, 0
        invoke BitBlt, [hMainDc], 0, 0, [ScreenWidth], [ScreenHeight], [hBufDC], 0, 0, SRCCOPY
        mov [HelpIsActive], 0
      jmp .full_skip

    @@:

    cmp [wparam], VK_TAB
    jne @F

    cmp [ConsoleInputMode], 1
    jne .switchTO1
    mov [ConsoleInputMode], 0
    mov [ConsoleCharsN], 0
    mov [ConsoleHistoryCurrI], -1 
    stdcall RedrawCommand
    jmp .finish
    .switchTO1:
    mov [ConsoleInputMode], 1
    stdcall DrawCursor
     
    jmp .full_skip

    @@:
    cmp [wparam], VK_ESCAPE
    je .wmdestroy

    cmp [ConsoleInputMode], 1
    je .handleConsoleInp

    .handleWindowInp:
    cmp [wparam], VK_SPACE
    jne .coninueAnalisis

    cmp [isDrawingActive], 1 
    je .finish
    cmp [PauseGame], 0
    je @F 
    mov [PauseGame], 0
    jmp .finish
    @@:
    mov [PauseGame], 1
    jmp .full_skip
    .coninueAnalisis:
    ; 'n' key
    cmp [wparam], 0x4E
    jne .finish
    mov [PutOnPauseNextTact], 1
    mov [PauseGame], 0

    jmp .finish
    ; @@:
    ; ; 's' key - save field 
    ; cmp [wparam], 0x53
    ; jne @F
    ; stdcall saveField, fname1

    ; @@:
    ; ; 'd' key - save configuration
    ; cmp [wparam], 0x44
    ; jne @F
    ; stdcall saveSettings, fname2

    ; @@:
    ; ; 'l' key - load configuration
    ; cmp [wparam], 0x4C
    ; jne @F
    ; stdcall loadSettings, fname2

    ; @@:
    ; ; 'k' key - load field
    ; cmp [wparam], 0x4B
    ; jne .finish 
    ; stdcall loadField, fname1
    

    .handleConsoleInp:

    cmp [wparam], VK_UP
    jne @F 
      ; skip if reached up limit
      mov eax, [ConsoleBufCurrSave]
      cmp [ConsoleHistoryCurrI], eax 
      jge .full_skip 
      inc [ConsoleHistoryCurrI]
      stdcall GetCommandFromHistory
      stdcall RedrawCommand
      jmp .full_skip
    @@:

    cmp [wparam], VK_DOWN
    jne @F 

      mov eax, [ConsoleBufCurrSave]
      cmp [ConsoleHistoryCurrI], -1 
      jle .full_skip 
      dec [ConsoleHistoryCurrI]
      stdcall GetCommandFromHistory
      stdcall RedrawCommand
      cmp [ConsoleCharsN], 0
      ja .full_skip
      stdcall DrawCursor
      invoke BitBlt, [hMainDc], 0, 0, [ScreenWidth], [ScreenHeight], [hBufDC], 0, 0, SRCCOPY
      jmp .full_skip
  @@:

    @@:
    ; enter
    cmp [wparam], VK_RETURN
    jne @F
    mov [ConsoleHistoryCurrI], -1
    cmp [ConsoleCharsN], 0
    mov [ConsoleInputMode], 0
    je  .finish
    
    mov edi, ConsoleInpBuf 
    add edi, [ConsoleCharsN] 
    mov byte[edi], 0
    stdcall ProcessCommand
    stdcall WriteMsg, ConsoleInpBuf
    mov [ConsoleCharsN], 0

    stdcall RedrawCommand
    
    jmp .full_skip

    @@:
    cmp [wparam], VK_BACK
    jne @F
    mov [ConsoleHistoryCurrI], -1
    cmp [ConsoleCharsN], 0
    jg .GreaterThenZero
    inc [ConsoleCharsN] 
    .GreaterThenZero:
      dec [ConsoleCharsN]
    
    cmp [ConsoleCharsN], 0
    jne .finish 

    stdcall DrawCursor

    jmp .full_skip

    @@:
    cmp [ConsoleCharsN], ConsoleBufSize
    jae .finish ; buffer is full, not procesing new char
    mov edi, ConsoleInpBuf
    add edi, [ConsoleCharsN]
    ; space

    cmp [wparam], VK_SPACE
    jne @F 
    mov byte[edi], ' '
    inc [ConsoleCharsN]
    jmp .finish
    
    @@:
    ; A
    cmp [wparam], 0x41
    jb .notALetter
    ; Z
    cmp [wparam], 0x5A
    ja .notALetter 

    mov [ConsoleHistoryCurrI], -1
    mov eax, [wparam]
    sub eax, 0x41
    add eax, 'a'
    mov byte[edi], al
    inc [ConsoleCharsN]
    
    jmp .finish
     
    .notALetter:
    ; 0
    cmp [wparam], 0x30
    jb .notADigit

    ; 9
    cmp [wparam], 0x39
    ja .notADigit

    mov [ConsoleHistoryCurrI], -1
    mov eax, [wparam]
    sub eax, 0x30
    add eax, '0'
    mov byte[edi], al
    inc [ConsoleCharsN]
    
    jmp .finish
    .notADigit: 

  jmp .finish

  .wmdestroy:
    invoke PostQuitMessage, 0
    xor eax, eax
    invoke  ExitProcess, 0
  
  .MouseClickHandle:
    local fieldX dd ?
    local fieldY dd ?
    local cellX dd ?
    local cellY dd ?

    cmp [HelpIsActive], 1
    je .full_skip

    ; getting Y, converting to field coords
    mov eax, [lparam]
    shr eax, 16
    sub eax, [YFieldOffset]
    sub eax, [FieldYInOffset]
    cmp eax, 0
    jl .finish 
    cmp eax, [FieldSizePx]
    jae .finish

    add eax, [YFieldOffset]
    add eax, [YFieldOffset]
    ; inversing y-axis direction
    mov ebx, [FieldZoneHeight]
    dec ebx 
    sub ebx, eax
    mov [fieldY], ebx

    ; doing same for x coords
    mov eax, [lparam]
    and eax, 0x0000FFFF
    sub eax, [XFieldOffset]
    sub eax, [FieldXInOffset]
    cmp eax, 0
    jl .finish 
    cmp eax, [FieldSizePx]
    jae .finish

    mov [fieldX], eax

    xor edx, edx 
    mov eax, [fieldX]
    div [CellSizePX]
    mov [cellX], eax

    mov eax, [fieldY]
    xor edx, edx 
    div [CellSizePX]
    mov [cellY], eax

    stdcall clearFieldCell, [cellX], [cellY]
    cmp [isDrawingAgent], 1
    jne @F 
    
      stdcall AddAgent, [cellX], [cellY]
        stdcall PrintStats
        invoke SetDIBitsToDevice, [hBufDC], [FieldXInOffset], [FieldYInOffset], [FieldZoneWidth], [FieldZoneHeight], 0, 0, 0, [FieldZoneHeight], [ScreenBufAddr], bmi, 0
        invoke BitBlt, [hMainDc], 0, 0, [ScreenWidth], [ScreenHeight], [hBufDC], 0, 0, SRCCOPY

    jmp .full_skip 
      stdcall AddFood, [cellX], [cellY]
    @@:
    cmp [isDrawingClear], 1 
    jne @F
      stdcall clearCellColor, [cellX], [cellY]
      stdcall PrintStats
      invoke SetDIBitsToDevice, [hBufDC], [FieldXInOffset], [FieldYInOffset], [FieldZoneWidth], [FieldZoneHeight], 0, 0, 0, [FieldZoneHeight], [ScreenBufAddr], bmi, 0
      invoke BitBlt, [hMainDc], 0, 0, [ScreenWidth], [ScreenHeight], [hBufDC], 0, 0, SRCCOPY
      jmp .full_skip
    @@:
    stdcall AddFood, [cellX], [cellY]
    stdcall PrintStats
    invoke SetDIBitsToDevice, [hBufDC], [FieldXInOffset], [FieldYInOffset], [FieldZoneWidth], [FieldZoneHeight], 0, 0, 0, [FieldZoneHeight], [ScreenBufAddr], bmi, 0
    invoke BitBlt, [hMainDc], 0, 0, [ScreenWidth], [ScreenHeight], [hBufDC], 0, 0, SRCCOPY

  jmp .full_skip



  .finish:
  
    cmp [ConsoleInputMode], 1
    jne @F
      xor eax, eax
      stdcall RedrawCommand
    @@:

  .full_skip:
  ret
endp