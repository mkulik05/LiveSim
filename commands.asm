proc ProcessCommand uses edi esi ecx edx
  cmp dword[ConsoleCharsN], COMMAND_EDIT_LEN + 2 ; command, space, number
  jb .ChechIsItAction

  mov ecx, COMMANDS_EDIT_N
  xor ebx, ebx ; index of selected command
  .checkCommand:  

    ; calculating index of current checked command in array
    mov edi, ConsoleEditCommands
    mov eax, COMMAND_EDIT_LEN 
    mul ebx
    add edi, eax

    mov esi, ConsoleInpBuf
    push ecx
    mov ecx, COMMAND_EDIT_LEN
    repe cmpsb 
    pop ecx
    jne .nextCommand ; command did not match
    jmp .foundCommand

    .nextCommand:
      inc ebx
  loop .checkCommand

  jmp .ChechIsItAction

  .foundCommand:

  mov edi, ConsoleInpBuf
  add edi, COMMAND_EDIT_LEN
  mov ecx, [ConsoleCharsN]
  sub ecx, COMMAND_EDIT_LEN

  .getToFirstNum:
    cmp byte[edi], '0'
    jb @F 
    cmp byte[edi], '9'
    ja @F

    jmp .foundNum
    @@:
    inc edi
  loop .getToFirstNum


  .foundNum:
    
  push ebx
  xor ebx, ebx
  xor eax, eax ; store result number
  .numberLoop:
    mov edx, 10
    mul edx
    cmp byte[edi], '0'
    jae @F 
    pop ebx
    jmp .ChechIsItAction
    @@:
    cmp byte[edi], '9'
    jbe @F 
    pop ebx
    jmp .ChechIsItAction
    @@:

    mov bl, byte[edi]
    add eax, ebx
    sub eax, '0'

    inc edi
  loop .numberLoop
  pop ebx

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

  jmp .StopProcessingOk

  .ChechIsItAction:
  cmp dword[ConsoleCharsN], COMMAND_ACTION_LEN ; command
  jb .StopProcessingErr

  mov ecx, COMMANDS_ACTION_N
  xor ebx, ebx ; index of selected command
  .checkCommand2:  

    ; calculating index of current checked command in array
    mov edi, ConsoleActionCommands
    mov eax, COMMAND_ACTION_LEN 
    mul ebx
    add edi, eax

    mov esi, ConsoleInpBuf
    push ecx
    mov ecx, COMMAND_ACTION_LEN
    repe cmpsb 
    pop ecx
    jne .nextCommand2 ; command did not match
    jmp .foundCommand2

    .nextCommand2:
      inc ebx
  loop .checkCommand2

  jmp .StopProcessingErr

  .foundCommand2:
  mov ecx, [ConsoleCharsN]
  sub ecx, COMMAND_EDIT_LEN
  cmp [ConsoleActionNeedParam + ebx], 0
  je .SkipParamParse

  mov edi, ConsoleInpBuf
  add edi, COMMAND_EDIT_LEN


  .getToFirstNum2:
    cmp byte[edi], '0'
    jb @F 
    cmp byte[edi], '9'
    ja @F

    jmp .foundNum2
    @@:
    inc edi
  loop .getToFirstNum2

  .foundNum2:
  push ebx
  xor ebx, ebx
  xor eax, eax ; store result number
  .numberLoop2:
    mov edx, 10
    mul edx
    cmp byte[edi], '0'
    jae @F 
    pop ebx
    jmp .StopProcessingErr
    @@:
    cmp byte[edi], '9'
    jbe @F 
    pop ebx
    jmp .StopProcessingErr
    @@:
    mov bl, byte[edi]
    add eax, ebx
    sub eax, '0'

    inc edi
  loop .numberLoop2

  pop ebx
  .SkipParamParse:
  cmp ecx, 0
  jne .StopProcessingErr
  mov esi, CommandsActionLabel
  shl ebx, 2
  add esi, ebx

  stdcall dword[esi], eax

  jmp .StopProcessingOk

  .StopProcessingErr:
    mov [IsCommandValid], 0
    jmp @F
  .StopProcessingOk:
    mov [IsCommandValid], 1  
  @@:
  ret 
endp

proc GetCommandFromHistory

  ; copying command from history  into console buffer
  cmp [ConsoleHistoryCurrI], -1
  jg @F 
    xor ecx, ecx
    jmp .stop
  @@:
  mov esi, [ConsoleBufCurrSave]
  sub esi, [ConsoleHistoryCurrI]
  mov esi, [ConsoleBufSaves + esi * 4]
  mov edi, ConsoleInpBuf
  mov ecx, ConsoleBufSize + 1
  rep movsb

  xor ecx, ecx
  mov edi, ConsoleInpBuf 
  .GetLen:
    cmp byte[edi], 0
    je .stop
    inc edi 
    inc ecx 
  jmp .GetLen

  .stop:
    mov [ConsoleCharsN], ecx
  ret
endp

proc CommandHelp, n
  local rect RECT
  mov [PauseGame], 1
  mov [HelpIsActive], 1

  push [lf.lfHeight]
  mov [lf.lfHeight], HINT_FONT_SIZE
  invoke CreateFontIndirect, lf
  invoke SelectObject, [hBufDC], eax

  mov [rect.top], 0

  mov eax, [FieldYInOffset]
  add eax, [FieldZoneHeight]
  mov [rect.bottom], eax


  
  mov [rect.left], 0
  mov eax, [FieldXInOffset]
  add eax, [FieldZoneWidth]
  mov [rect.right], eax
  lea eax, [rect]
  invoke FillRect, [hBufDC], eax, [bkgBrush]

  mov eax, [YFieldOffset] 
  add eax, HINT_FONT_SIZE * 2
  mov [rect.bottom], eax

  mov eax, [YFieldOffset]
  mov [rect.top], eax

  mov eax, [FieldXInOffset]
  mov [rect.left], eax

  mov ecx, HINTS_COMMANDS_AMOUNT
  mov esi, commands ; curr text to write
  
  .PrintTableLine:
    push ecx
    mov eax, [FieldXInOffset]
    mov [rect.left], eax

    mov eax, [FieldXInOffset]
    add eax, FIRST_COLUMN_WIDTH
    mov [rect.right], eax

    lea eax, [rect]
    invoke DrawText, [hBufDC], esi, -1, eax, DT_LEFT

    .findLastZero:
      cmp byte[esi], 0
      je @F 
      inc esi
      jmp .findLastZero
    
    @@:
      inc esi

    
    add [rect.left], FIRST_COLUMN_WIDTH
    add [rect.right], SECOND_COLUMN_WIDTH
    lea eax, [rect]
    invoke DrawText, [hBufDC], esi, -1, eax, DT_LEFT
    lea eax, [rect]
    ; invoke FrameRect, [hBufDC], eax, blackBrush

    .findZero:
      cmp byte[esi], 0
      je @F 
      inc esi
      jmp .findZero
    
    @@:
      inc esi

    add [rect.left], SECOND_COLUMN_WIDTH
    mov eax, [FieldXInOffset]
    add eax, [FieldSizePx]
    mov [rect.right], eax
    lea eax, [rect]
    invoke DrawText, [hBufDC], esi, -1, eax, DT_LEFT
    lea eax, [rect]
    ; invoke FrameRect, [hBufDC], eax, blackBrush
    
    add [rect.top], HINT_FONT_SIZE * 2
    add [rect.bottom], HINT_FONT_SIZE * 2
  
    .findLastLastZero:
      cmp byte[esi], 0
      je @F 
      inc esi
      jmp .findLastLastZero
    
    @@:
      inc esi

  pop ecx 
  dec ecx
  cmp ecx, 0
  jne .PrintTableLine

  add [rect.top], HINT_FONT_SIZE * 2
  add [rect.bottom], HINT_FONT_SIZE * 2
  mov eax, [FieldXInOffset]
  mov [rect.left], eax
  lea eax, [rect]
  invoke DrawText, [hBufDC], ToContinueMsg, -1, eax, DT_CENTER


  invoke BitBlt, [hMainDc], 0, 0, [ScreenWidth], [ScreenHeight], [hBufDC], 0, 0, SRCCOPY
  pop [lf.lfHeight]
  invoke CreateFontIndirect, lf
  invoke SelectObject, [hBufDC], eax

  ret 
endp

proc CommandChangeFieldSize uses ebx, n
  mov eax, [n]
  mov ebx, [ScreenHeight]
  sub ebx, 2
  cmp eax, ebx
  ja @F
    mov [FieldSize], eax
    jmp .continue
  @@:
    mov [FieldSize], ebx
  .continue:
  invoke HeapFree, [HeapHandle], 0, [FieldAddr]
  mov [TotalTacts], 0
  mov [ConsoleCharsN], 0
  ; mov [PauseGame], 1
  mov [AgentsSize], 0
  mov [FoodSize], 0
  mov [ConsoleBufCurrSave], -1
  stdcall EntryPoint  
  ret 
endp

proc CommandReset, n
  mov [PauseGame], 1
  mov [TotalTacts], 0
  mov [ConsoleCharsN], 0
  mov [AgentsSize], 0
  mov [FoodSize], 0
  mov [ConsoleBufCurrSave], -1
  stdcall EntryPoint  
  ret 
endp


proc CommandChangeFoodSpawnAmount, n
  mov eax, [n]
  mov [NextFoodSpawnNMax], eax
  stdcall RandInt, eax 
  mov [NextFoodSpawnN], eax
  ret 
endp

proc CommandAgentDraw, n
  cmp [isCursorShown], 0
  jne @F
  invoke ShowCursor, TRUE
  mov [isCursorShown], 1
  @@:
  mov [PauseGame], 1
  mov [isDrawingActive], 1
  mov [isDrawingAgent], 1
  mov [isDrawingClear], 0
  ret
endp

proc CommandFoodDraw, n
  cmp [isCursorShown], 0
  jne @F
  invoke ShowCursor, TRUE
  mov [isCursorShown], 1
  @@:
  mov [PauseGame], 1
  mov [isDrawingActive], 1
  mov [isDrawingAgent], 0
  mov [isDrawingClear], 0
  ret 
endp

proc CommandStopDraw, n
  cmp [isCursorShown], 1
  jne @F
  invoke ShowCursor, FALSE
  mov [isCursorShown], 0
  @@:
  mov [isDrawingActive], 0
  mov [isDrawingClear], 0
  ret 
endp

proc CommandClearDraw, n
  cmp [isCursorShown], 0
  jne @F
  invoke ShowCursor, TRUE
  mov [isCursorShown], 1
  @@:
  mov [PauseGame], 1
  mov [isDrawingAgent], 0
  mov [isDrawingActive], 1
  mov [isDrawingClear], 1
  ret 
endp