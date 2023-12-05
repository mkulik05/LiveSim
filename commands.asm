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
    invoke MessageBox, 0, ConsoleErrorMsg, ConsoleErrorMsg, MB_OK
    stdcall WriteMsg, ConsoleErrorMsg
  .StopProcessingOk:
  ret 
endp



proc CommandChangeFieldSize, num
  mov eax, [num]
  mov [FieldSize], eax

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

proc CommandReset, num
  mov [TotalTacts], 0
  mov [ConsoleCharsN], 0
  mov [AgentsSize], 0
  mov [FoodSize], 0
  mov [ConsoleBufCurrSave], -1
  stdcall EntryPoint  
  ret 
endp

proc CommandChangeFoodSpawnAmount, num 
  mov eax, [num]
  mov [NextFoodSpawnNMax], eax
  stdcall RandInt, eax 
  mov [NextFoodSpawnN], eax
  ret 
endp