proc saveField uses esi edi ebx edx, fName
  local buf dd 0
  local hF dd ?
      
  invoke CreateFile, [fName], GENERIC_WRITE, 0, 0, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
  mov [hF], eax

  ;  saving constants
  mov eax, [FieldSize]
  mov [buf], eax
  lea eax, [buf]
  invoke WriteFile, [hF], eax, 4, 0, 0

  mov eax, [AgentsSize]
  mov [buf], eax
  lea eax, [buf]
  invoke WriteFile, [hF], eax, 4, 0, 0

  mov eax, [FoodSize]
  mov [buf], eax
  lea eax, [buf]
  invoke WriteFile, [hF], eax, 4, 0, 0

  mov esi, [AgentsAddr]
  mov ecx, [AgentsSize]
  cmp ecx, 0
  je .skipAgentsSaving
  .SaveAgent:
    push ecx

    ; in future, all this size may be decreazed based on fields params 
    ; (size, max energy, max amount of instruction and so on) 
    
    mov eax, [esi + AGENT_COORDS_OFFSET]
    mov [buf], eax
    lea eax, [buf]
    invoke WriteFile, [hF], eax, 4, 0, 0

    mov ax, word[esi + AGENT_ENERGY_OFFSET]
    mov word[buf], ax
    lea eax, [buf]
    invoke WriteFile, [hF], eax, 2, 0, 0

    mov ax, word[esi + AGENT_CURR_INSTR_OFFSET]
    mov word[buf], ax
    lea eax, [buf]
    invoke WriteFile, [hF], eax, 2, 0, 0

    mov ax, word[esi + AGENT_INSTR_NUM_OFFSET]
    mov word[buf], ax
    lea eax, [buf]
    invoke WriteFile, [hF], eax, 2, 0, 0

    movzx edi, word[esi + AGENT_INSTR_NUM_OFFSET]
    xor ebx, ebx
    .saveInstructions:
        push esi 
        push ebx 
        push edi
        mov al, byte[esi + ebx + AGENT_INSTR_VEC_OFFSET]
        mov byte[buf], al 
        lea eax, [buf]
        invoke WriteFile, [hF], eax, 1, 0, 0
        pop edi 
        pop ebx 
        pop esi

        inc ebx
        dec edi
        cmp edi, 0
    jg .saveInstructions
    
    add esi, [AgentRecSize]
  pop ecx
  dec ecx 
  cmp ecx, 0
  ja .SaveAgent


  .skipAgentsSaving:  

  mov esi, [FoodAddr]
  mov ecx, [FoodSize]
  cmp ecx, 0
  je .skipFoodSaving
  .SaveFood:
    push ecx

    ; in future, all this size may be decreazed based on fields params 
    ; (size, and stuff) 
    mov eax, [esi + FOOD_COORDS_OFFSET]
    mov [buf], eax
    lea eax, [buf]
    invoke WriteFile, [hF], eax, 4, 0, 0

    mov ax, word[esi + FOOD_AMOUNT_OFFSET]
    mov word[buf], ax
    lea eax, [buf]
    invoke WriteFile, [hF], eax, 2, 0, 0

    mov ax, word[esi + FOOD_MAX_AMOUNT_OFFSET]
    mov word[buf], ax
    lea eax, [buf]
    invoke WriteFile, [hF], eax, 2, 0, 0

    mov ax, word[esi + FOOD_GROW_VALUE_OFFSET]
    mov word[buf], ax
    lea eax, [buf]
    invoke WriteFile, [hF], eax, 2, 0, 0
    
    add esi, [FoodRecSize]
    pop ecx
  loop .SaveFood


  .skipFoodSaving:

  invoke CloseHandle, [hF]
  ; invoke MessageBox, 0, savedMsg, savedMsg, MB_OK
  ret
endp

proc loadField uses esi edi ebx edx, fName
  local buf dd 0
  local hF dd ?
  local lastI dd 0
  
  invoke CreateFile, [fName], GENERIC_READ, 0, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
  mov [hF], eax

  ;  load constants
  lea eax, [buf]
  invoke ReadFile, [hF], eax, 4, 0, 0
  mov eax, [buf]
  mov [FieldSize], eax

  invoke HeapFree, [HeapHandle], 0, [FieldAddr] ; freeing old buffer
  stdcall Initialisation ; based on new field size, alloc mem 

  lea eax, [buf]
  invoke ReadFile, [hF], eax, 4, 0, 0
  mov eax, [buf]
  mov [AgentsSize], eax

  lea eax, [buf]
  invoke ReadFile, [hF], eax, 4, 0, 0
  mov eax, [buf]
  mov [FoodSize], eax

  mov esi, [AgentsAddr]
  mov ecx, [AgentsSize]
  cmp ecx, 0
  je .skipAgentsLoading
  .LoadAgent:
    push ecx

    ; in future, all this size may be decreazed based on fields params 
    ; (size, max energy, max amount of instruction and so on) 
  
    lea eax, [buf]
    invoke ReadFile, [hF], eax, 4, 0, 0
    mov eax, [buf]
    mov [esi + AGENT_COORDS_OFFSET], eax

    lea eax, [buf]
    invoke ReadFile, [hF], eax, 2, 0, 0
    mov ax, word[buf]
    mov word[esi + AGENT_ENERGY_OFFSET], ax

    lea eax, [buf]
    invoke ReadFile, [hF], eax, 2, 0, 0
    mov ax, word[buf]
    mov word[esi + AGENT_CURR_INSTR_OFFSET], ax

    lea eax, [buf]
    invoke ReadFile, [hF], eax, 2, 0, 0
    mov ax, word[buf]
    mov word[esi + AGENT_INSTR_NUM_OFFSET], ax

    movzx edi, word[esi + AGENT_INSTR_NUM_OFFSET]
    xor ebx, ebx
    .loadInstructions:
        push esi 
        push ebx 
        push edi
        lea eax, [buf]
        invoke ReadFile, [hF], eax, 1, 0, 0
        mov al, byte[buf]
        mov byte[esi + ebx + AGENT_INSTR_VEC_OFFSET], al
        pop edi 
        pop ebx 
        pop esi

        inc ebx
        dec edi
        cmp edi, 0
    jg .loadInstructions
    mov ecx, AGENT_MAX_INSTRUCTIONS_N
    sub ecx, ebx
    cmp ecx, 0
    jng @F
    .align:
      mov byte[esi + ebx + AGENT_INSTR_VEC_OFFSET], 0
      inc ebx 
    loop .align
    @@:

    mov edi, [FieldAddr]
    mov ebx, [esi + AGENT_COORDS_OFFSET]
    mov eax, [lastI]
    mov [edi + ebx * FIELD_CELL_SIZE], eax 
    or dword[edi + ebx * FIELD_CELL_SIZE], FIELD_AGENT_STATE
    inc [lastI]
    add esi, [AgentRecSize]
  pop ecx
  dec ecx 
  cmp ecx, 0
  ja .LoadAgent


  .skipAgentsLoading:  
  mov [lastI], 0

  mov esi, [FoodAddr]
  mov ecx, [FoodSize]
  cmp ecx, 0
  je .skipFoodSaving
  .LoadFood:
    push ecx

    ; in future, all this size may be decreazed based on fields params 
    ; (size, and stuff) 
    lea eax, [buf]
    invoke ReadFile, [hF], eax, 4, 0, 0
    mov eax, [buf]
    mov [esi + FOOD_COORDS_OFFSET], eax

    lea eax, [buf]
    invoke ReadFile, [hF], eax, 2, 0, 0
    mov eax, [buf]
    mov [esi + FOOD_AMOUNT_OFFSET], eax

    lea eax, [buf]
    invoke ReadFile, [hF], eax, 2, 0, 0
    mov eax, [buf]
    mov [esi + FOOD_MAX_AMOUNT_OFFSET], eax

    lea eax, [buf]
    invoke ReadFile, [hF], eax, 2, 0, 0
    mov eax, [buf]
    mov [esi + FOOD_GROW_VALUE_OFFSET], eax
    
    mov edi, [FieldAddr]
    mov ebx, [esi + FOOD_COORDS_OFFSET]
    mov eax, [lastI]
    mov [edi + ebx * FIELD_CELL_SIZE], eax 
    or dword[edi + ebx * FIELD_CELL_SIZE], FIELD_FOOD_STATE
    inc [lastI]
    add esi, [FoodRecSize]
    pop ecx

  dec ecx
  cmp ecx, 0
  ja .LoadFood


  .skipFoodSaving:

  invoke CloseHandle, [hF]
  mov [TotalTacts], 0
  stdcall start
  ret
endp

proc saveSettings, fName
  local buf dd 0
  local hF dd ?
      
  invoke CreateFile, [fName], GENERIC_WRITE, 0, 0, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
  mov [hF], eax

  mov ecx, AMOUNT_OF_SETTINGS
  mov esi, SettingsToSave
  .startSaving:

    push esi 
    push ecx

    mov edi, [esi] ; got param addr
    mov eax, [edi]
    mov [buf], eax
    lea eax, [buf]
    invoke WriteFile, [hF], eax, 4, 0, 0

    pop ecx 
    pop esi

    add esi, 4
  loop .startSaving

  invoke CloseHandle, [hF]
  invoke MessageBox, 0, savedMsg, savedMsg, MB_OK
  ret 
endp

proc loadSettings, fName
  local buf dd 0
  local hF dd ?
      
  invoke CreateFile, [fName], GENERIC_READ, 0, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
  mov [hF], eax

  mov ecx, AMOUNT_OF_SETTINGS
  mov esi, SettingsToSave
  .startLoading:

    push esi 
    push ecx

    lea eax, [buf]
    invoke ReadFile, [hF], eax, 4, 0, 0
    mov eax, [buf]
    mov edi, [esi]
    mov [edi], eax

    pop ecx 
    pop esi

    add esi, 4
  loop .startLoading

  invoke CloseHandle, [hF]
  invoke MessageBox, 0, savedMsg, savedMsg, MB_OK
  ret 
endp