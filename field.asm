; generates field with food, with agents and so on
proc fillField
  ; get emount of cells to generate
  mov eax, [FieldSize] 
  mul [FieldSize]

  xor ebx, ebx
  xor esi, esi
  mov ecx, eax
  loopStart:
    rdrand ax
    
    cmp al, 128
    jb EmptyCell
    cmp al, 200
    jb Food
    jmp Agent

    EmptyCell:
      mov esi, [FieldAddr]
      mov dword[esi + ebx * FIELD_CELL_SIZE], 0
      jmp @F
    Food:
      ; chech is there enough memory
      mov eax, [FoodCapacity]
      cmp eax, [FoodSize]
      jle EmptyCell 

      mov eax, [FoodSize]
      or eax, FIELD_FOOD_STATE

      ; food cell - oldest bit is 1
      mov esi, [FieldAddr]
      mov dword[esi + ebx * FIELD_CELL_SIZE], eax  


      mov edi, [FoodAddr]
      mov eax, [FoodSize]
      mul [FoodRecSize]
      add edi, eax
      mov eax, [FieldSize]  ; may be optimised mb
      mul [FieldSize]
      sub eax, ecx
      mov dword[edi + FOOD_COORDS_OFFSET], eax ; curr coords
      stdcall RandInt, [FoodMaxInitAmount]
      inc eax ; should be at least 1
      mov word[edi + FOOD_AMOUNT_OFFSET], ax ; save food amount

      mov eax, [FoodMaxValue]
      sub eax, [FoodMaxInitAmount]
      stdcall RandInt, eax
      add eax, [FoodMaxInitAmount]
      mov word[edi + FOOD_MAX_AMOUNT_OFFSET], ax

      stdcall RandInt, [FoodGrowMaxValue]
      mov word[edi + FOOD_GROW_VALUE_OFFSET], ax ; save food growing amount

      inc [FoodSize]
      jmp @F

    Agent:

      ; if agents vector is filed, skipping it
      mov eax, [AgentsCapacity]
      cmp eax, [AgentsSize]
      jle EmptyCell

      ; filling cell in game field and then agents vector
      mov eax, [AgentsSize]
      or eax, FIELD_AGENT_STATE

      ; agent cell - pre oldest bit is 1
      mov esi, [FieldAddr]
      mov dword[esi + ebx * FIELD_CELL_SIZE], eax


      mov eax, [AgentRecSize]
      mul [AgentsSize]
      mov edi, [AgentsAddr]
      add edi, eax

      mov eax, [FieldSize]  ; may be optimised mb
      mul [FieldSize]
      sub eax, ecx
      mov dword[edi + AGENT_COORDS_OFFSET], eax ; curr coords
      mov eax, [AgentInitEnergy]
      shr eax, 1
      stdcall RandInt, eax
      mov word[edi + AGENT_ENERGY_OFFSET], ax
      mov eax, [AgentInitEnergy]
      shr eax, 1
      add word[edi + AGENT_ENERGY_OFFSET], ax
      mov word[edi + AGENT_CURR_INSTR_OFFSET], 0

      mov eax, AGENT_MAX_INSTRUCTIONS_N 
      ; used to not have 0 instructions
      dec eax
      stdcall RandInt, eax
      inc ax
      mov word[edi + AGENT_INSTR_NUM_OFFSET], ax 
      push ecx
      mov ecx, eax
      xor ebp, ebp ; curr instruction
      RandInstruction:
        stdcall RandInt, [AgentTaskMaxInd]
        mov byte[ebp + edi + AGENT_INSTR_VEC_OFFSET], al
        inc ebp
      loop RandInstruction
      pop ecx

      inc dword[AgentsSize]
    
  @@:
    add ebx, 1
    dec ecx
    cmp ecx, 0
    jz stopLoop
    jmp loopStart 
  stopLoop:
  mov eax, [AgentsSize]
  ret  
endp

proc clearFieldCell uses ebx esi, X, Y 
  ; got lin size
  mov eax, [Y]
  mul [FieldSize]
  add eax, [X]
  mov ebx, eax

  mov esi, [FieldAddr]
  mov eax, [esi + ebx * FIELD_CELL_SIZE]

  test eax, FIELD_AGENT_STATE
  jz @F 
  and eax, FIELD_SAFE_MASK
  stdcall removeVecItem, [AgentsAddr], AgentsSize, [AgentRecSize], AGENT_COORDS_OFFSET, eax
  mov dword[esi + ebx * FIELD_CELL_SIZE], 0
  jmp .finish
  @@:
  test eax, FIELD_FOOD_STATE
  jz .finish
  and eax, FIELD_SAFE_MASK
  stdcall removeVecItem, [FoodAddr], FoodSize, [FoodRecSize], FOOD_COORDS_OFFSET, eax
  mov dword[esi + ebx * FIELD_CELL_SIZE], 0

  .finish:
  ret 
endp

proc clearCellColor, X, Y 

  mov eax, [Y]
  mul [FieldSize]
  add eax, [X]
  stdcall bufUpdateCellColor, eax, EMPTY_COLOR
  ret 
endp

proc AddFood uses edi esi ebx, X, Y 
  mov eax, [Y]
  mul [FieldSize]
  add eax, [X]
  mov ebx, eax
  mov esi, [FieldAddr]
  mov eax, [FoodSize]
  mov dword[esi + ebx * FIELD_CELL_SIZE], eax 
  or dword[esi + ebx * FIELD_CELL_SIZE], FIELD_FOOD_STATE

  mov edi, [FoodAddr]
  mov eax, [FoodSize]
  mul [FoodRecSize]
  add edi, eax
  mov dword[edi + FOOD_COORDS_OFFSET], ebx ; curr coords
  stdcall RandInt, [FoodMaxInitAmount]
  inc eax ; should be at least 1
  mov word[edi + FOOD_AMOUNT_OFFSET], ax ; save food amount

  stdcall CalcFoodColor, eax 
  stdcall bufUpdateCellColor, dword[edi + FOOD_COORDS_OFFSET], eax

  mov eax, [FoodMaxValue]
  sub eax, [FoodMaxInitAmount]
  stdcall RandInt, eax
  add eax, [FoodMaxInitAmount]
  mov word[edi + FOOD_MAX_AMOUNT_OFFSET], ax

  stdcall RandInt, [FoodGrowMaxValue]
  mov word[edi + FOOD_GROW_VALUE_OFFSET], ax ; save food growing amount

  inc [FoodSize]

  ret
endp


proc AddAgent uses edi esi ebx, X, Y 
  mov eax, [Y]
  mul [FieldSize]
  add eax, [X]
  mov ebx, eax
  mov esi, [FieldAddr]
  mov eax, [AgentsSize]
  mov dword[esi + ebx * FIELD_CELL_SIZE], eax 
  or dword[esi + ebx * FIELD_CELL_SIZE], FIELD_AGENT_STATE

  mov eax, [AgentRecSize]
  mul [AgentsSize]
  mov edi, [AgentsAddr]
  add edi, eax

  mov dword[edi + AGENT_COORDS_OFFSET], ebx ; curr coords
  mov eax, [AgentInitEnergy]
  shr eax, 1
  stdcall RandInt, eax
  mov word[edi + AGENT_ENERGY_OFFSET], ax
  mov eax, [AgentInitEnergy]
  shr eax, 1
  add word[edi + AGENT_ENERGY_OFFSET], ax
  movzx eax, word[edi + AGENT_ENERGY_OFFSET]
  stdcall CalcAgentColor, eax 
  stdcall bufUpdateCellColor, dword[edi + AGENT_COORDS_OFFSET], eax
  mov word[edi + AGENT_CURR_INSTR_OFFSET], 0

  mov eax, AGENT_MAX_INSTRUCTIONS_N 
  ; used to not have 0 instructions
  dec eax
  stdcall RandInt, eax
  inc ax
  mov word[edi + AGENT_INSTR_NUM_OFFSET], ax 
  mov ecx, eax
  push ebp
  xor ebp, ebp ; curr instruction
  .RandInstruction:
    stdcall RandInt, [AgentTaskMaxInd]
    mov byte[ebp + edi + AGENT_INSTR_VEC_OFFSET], al
    inc ebp
  loop .RandInstruction
  pop ebp

  inc [AgentsSize]

  ret
endp
