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


proc WriteMsg uses edi esi ebx, Msg
  local rect RECT

  ; initing them in the start, cause they are constant
  mov eax, [FieldXOffset]
  add eax, [FieldWidth] 
  add [rect.left], eax
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
    invoke FillRect, [hDC], eax, [bkgBrush]
    lea eax, [rect] 
    invoke DrawText, [hDC], [Msg], -1, eax, DT_LEFT

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
      lea eax, [rect] 
      invoke FillRect, [hDC], eax, [bkgBrush]
      lea eax, [rect] 
      invoke DrawText, [hDC], [ConsoleBufSaves + (ebx - 1) * 4], -1, eax, DT_LEFT
      add [rect.top], TEXT_FONT_SIZE * 2
      add [rect.bottom], TEXT_FONT_SIZE * 2
      pop ecx
      inc ebx
    loop .shiftText

    mov ebx, [ConsoleBufSavesN]
    pop edx 
    mov [ConsoleBufSaves + (ebx - 1) * 4], edx

    ; saving text to corresponding slot (so history will work (in future:)))
    mov ecx, ConsoleBufSize + 1
    mov edi, [ConsoleBufSaves + (ebx - 1) * 4]
    mov esi, [Msg]
    rep movsb

    lea eax, [rect] 
    invoke FillRect, [hDC], eax, [bkgBrush]
    lea eax, [rect] 
    invoke DrawText, [hDC], [ConsoleBufSaves + (ebx - 1) * 4], -1, eax, DT_LEFT

    .stop:

  ret 
endp

proc DrawCursor uses edi eax
  local rect RECT

  mov eax, [FieldXOffset]
  add eax, [FieldWidth] 
  mov [rect.left], eax
  add [rect.left], TEXT_MARGIN_LEFT / 2
  mov eax, [ScreenWidth]
  mov [rect.right], eax

  mov eax, [ScreenHeight]
  mov [rect.bottom], eax
  sub eax, TEXT_FONT_SIZE * 2
  mov [rect.top], eax
  lea eax, [rect] 
  invoke FillRect, [hDC], eax, [bkgBrush]
  lea eax, [rect] 
  invoke DrawText, [hDC], ConsoleActiveText, -1, eax, DT_LEFT
  ret 
endp

proc RedrawCommand uses edi eax
  local rect RECT
  mov edi, ConsoleInpBuf 
  add edi, [ConsoleCharsN]
  mov byte[edi], 0

 
  mov eax, [FieldXOffset]
  mov [rect.left], eax
  mov eax, [FieldWidth] 
  add [rect.left], eax
  add [rect.left], TEXT_MARGIN_LEFT / 2
  mov eax, [ScreenWidth]
  mov [rect.right], eax

  mov eax, [ScreenHeight]
  mov [rect.bottom], eax
  sub eax, TEXT_FONT_SIZE * 2
  mov [rect.top], eax
  lea eax, [rect] 
  invoke FillRect, [hDC], eax, [bkgBrush]
  lea eax, [rect] 
  invoke DrawText, [hDC], ConsoleInpBuf, -1, eax, DT_LEFT
  ret 
endp

proc ProcessCommand uses edi esi ecx edx
  cmp dword[ConsoleCharsN], COMMAND_LEN + 2 ; command, space, number
  jb .stopProcessing

  mov ecx, COMMANDS_N
  xor ebx, ebx ; index of selected command
  .checkCommand:  

    ; calculating index of current checked command in array
    mov edi, ConsoleCommands
    mov eax, COMMAND_LEN 
    mul ebx
    add edi, eax

    mov esi, ConsoleInpBuf
    push ecx
    mov ecx, COMMAND_LEN
    repe cmpsb 
    pop ecx
    jne .nextCommand ; command did not match
    jmp .foundCommand

    .nextCommand:
      inc ebx
  loop .checkCommand

  jmp .stopProcessing

  .foundCommand:

  ; so StrToIntW function will stop after meeting zero
  mov edi, ConsoleInpBuf
  add edi, COMMAND_LEN
  mov ecx, [ConsoleCharsN]
  sub ecx, COMMAND_LEN

  .getToFirstNum:
    cmp byte[edi], '0'
    jb @F 
    cmp byte[edi], '9'
    ja @F

    jmp .foundNum
    @@:
    inc edi
  loop .getToFirstNum

  jmp .stopProcessing

  .foundNum:
  xor eax, eax ; store result number
  .numberLoop:
    mov edx, 10
    mul edx
    cmp byte[edi], '0'
    jb .stopProcessing
    cmp byte[edi], '9'
    ja .stopProcessing

    add al, byte[edi]
    sub eax, '0'

    inc edi
  loop .numberLoop

  ; parsed number
  mov esi, CommandsEditLabel
  shl ebx, 2
  add esi, ebx

  mov esi, [esi]
  mov [esi], eax

  ; checking there to not slow dowd game loop
  ; AgentEnergyToMove + 2 <= AgentMinEnergyToClone
  ; cause energy is splitted, then decresed, so it should be hndled correctly
  mov ebx, [AgentEnergyToClone]
  add ebx, 2

  cmp ebx, [AgentMinEnergyToClone]
  jbe @F 
    mov [AgentMinEnergyToClone], ebx
    sub [AgentMinEnergyToClone], 2 
  @@: 

  .stopProcessing:

  ret 
endp

proc WindowProc uses ebx esi edi, hwnd, wmsg, wparam, lparam
  cmp [wmsg], WM_DESTROY
  je .wmdestroy
  cmp [wmsg], WM_KEYDOWN
  jne @F 

  cmp [ConsoleInputMode], 1
  jne .keyDown
  mov eax, [lparam]
  shr eax, 31 
  jc .full_skip
  
  jmp .keyDown

  @@:
  invoke DefWindowProc, [hwnd], [wmsg], [wparam], [lparam]
  jmp .full_skip

  .keyDown:
    cmp [wparam], VK_TAB
    jne @F

    cmp [ConsoleInputMode], 1
    jne .switchTO1
    mov [ConsoleInputMode], 0
    mov [ConsoleCharsN], 0
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

    .handleConsoleInp:

    ; enter
    cmp [wparam], VK_RETURN
    jne @F
    cmp [ConsoleCharsN], 0
    mov [ConsoleInputMode], 0
    je  .finish
    
    mov edi, ConsoleInpBuf 
    add edi, [ConsoleCharsN] 
    mov byte[edi], 0
    stdcall WriteMsg, ConsoleInpBuf
    stdcall ProcessCommand
    mov [ConsoleCharsN], 0

    stdcall RedrawCommand
    
    jmp .full_skip

    @@:
    cmp [wparam], VK_BACK
    jne @F
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
  .finish:
  
    cmp [ConsoleInputMode], 1
    jne @F
      xor eax, eax
      stdcall RedrawCommand
    @@:

  .full_skip:
  ret
endp