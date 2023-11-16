proc GenFood uses ecx ebx esi edi
  mov ecx, [NextFoodSpawnN]
  .SpawnFood:

    ; getting index in which food will be spawned
    mov eax, [FieldSize]
    mul eax 
    dec eax
    stdcall RandInt, eax
    mov ebx, eax

    mov esi, [FieldAddr]
    shl eax, 2
    add esi, eax 
    mov eax, [esi] ; got field cell

    test eax, FIELD_AGENT_STATE
    jz .checkIsItFood
    mov edi, [AgentsAddr]
    and eax, FIELD_SAFE_MASK ; got agent index in vector
    mul [AgentRecSize]
    add edi, eax  ; got agent addr

    stdcall RandInt, [SpawnedFoodMaxAmount]
    inc eax ; got food amount

    add word [edi + AGENT_ENERGY_OFFSET], ax 
    jnc @F
      mov word [edi + AGENT_ENERGY_OFFSET], 0xFFFF  
    @@:
    jmp .finish

    .checkIsItFood:
    test eax, FIELD_FOOD_STATE
    jz .itIsEmptyCell
    mov edi, [FoodAddr]
    and eax, FIELD_SAFE_MASK ; got agent index in vector
    mul [FoodRecSize]
    add edi, eax
    
    stdcall RandInt, [SpawnedFoodMaxAmount]
    inc eax
    add word[edi + FOOD_AMOUNT_OFFSET], ax
    jnc @F 
      mov word[edi + FOOD_AMOUNT_OFFSET], 0xFFFF
    @@:


    ; increase max food amount
    stdcall RandInt, [FoodMaxValue]
    add word[edi + FOOD_MAX_AMOUNT_OFFSET], ax
    jnc @F 
      mov word[edi + FOOD_MAX_AMOUNT_OFFSET], 0xFFFF
    @@:

    stdcall RandInt, [FoodGrowMaxValue]
    add word[edi + FOOD_GROW_VALUE_OFFSET], ax
    jnc @F 
      mov word[edi + FOOD_GROW_VALUE_OFFSET], 0xFFFF
    @@:

    jmp .finish

    .itIsEmptyCell:
      mov eax, [FoodCapacity]
      cmp eax, [FoodSize]
      jle .finish 

      mov edi, [FoodAddr]
      mov eax, [FoodSize]
      mul [FoodRecSize]
      add edi, eax ; got new food start addr

      mov dword[edi + FOOD_COORDS_OFFSET], ebx ; curr coords
      stdcall RandInt, [SpawnedFoodMaxAmount]
      inc eax ; should be at least 1
      mov word[edi + FOOD_AMOUNT_OFFSET], ax ; save food amount

      mov eax, [FoodMaxValue]
      sub eax, [FoodMaxInitAmount]
      stdcall RandInt, eax
      add eax, [FoodMaxInitAmount]
      mov word[edi + FOOD_MAX_AMOUNT_OFFSET], ax
      
      stdcall RandInt, [FoodGrowMaxValue]
      mov word[edi + FOOD_GROW_VALUE_OFFSET], ax

      mov esi, [FieldAddr]
      mov eax, ebx 
      shl eax, 2
      add esi, eax
      mov eax, [FieldSize]
      mov [esi], eax
      or dword[esi], FIELD_FOOD_STATE

      movzx eax, word[edi + FOOD_AMOUNT_OFFSET]
      stdcall CalcFoodColor, eax
      stdcall bufUpdateCellColor, ebx, eax

      inc [FoodSize]

    .finish:
      dec ecx 
      cmp ecx, 0
      jne .SpawnFood
  ret 
endp

proc GrowFood uses ecx edi
  mov ecx, [FoodSize]
  cmp ecx, 0
  jbe .stop
  mov edi, [FoodAddr]
  .loopStart:

    ; to optimize mb
    movzx eax, word[edi + FOOD_GROW_VALUE_OFFSET]
    add word[edi + FOOD_AMOUNT_OFFSET], ax
    movzx eax, word[edi + FOOD_MAX_AMOUNT_OFFSET]
    cmp word[edi + FOOD_AMOUNT_OFFSET], ax
    jb @F
      mov word[edi + FOOD_AMOUNT_OFFSET], ax
    @@:
    movzx eax, word[edi + FOOD_AMOUNT_OFFSET]
    stdcall CalcFoodColor, eax
    stdcall bufUpdateCellColor, [edi + FOOD_COORDS_OFFSET], eax
    add edi, [FoodRecSize]
  loop .loopStart
  .stop:
  ret 
endp