
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
      mov byte[esi + ebx], 0
      jmp @F
    Food:
      ; chech is there enough memory
      mov eax, [FoodCapacity]
      cmp eax, [FoodSize]
      jle EmptyCell 

      mov ax, FIELD_FOOD_STATE

      ; food cell - oldest bit is 1
      mov esi, [FieldAddr]
      mov byte[esi + ebx], al      


      mov edi, [FoodAddr]
      mov eax, [FoodSize]
      mul [FoodRecSize]
      add edi, eax
      mov eax, [FieldSize]  ; may be optimised mb
      mul [FieldSize]
      sub eax, ecx
      mov dword[edi + FOOD_COORDS_OFFSET], eax ; curr coords
      stdcall RandInt, [FoodMaxAmount]
      mov word[edi + FOOD_AMOUNT_OFFSET], ax ; save food amount
      inc [FoodSize]
      jmp @F

    Agent:

      ; if agents vector is filed, skipping it
      mov eax, [AgentsCapacity]
      cmp eax, [AgentsSize]
      jle EmptyCell

      ; filling cell in game field and then agents vector
      mov eax, FIELD_AGENT_STATE

      ; agent cell - pre oldest bit is 1
      mov esi, [FieldAddr]
      mov byte[esi + ebx], al


      mov esi, [AgentsSize]
      mov eax, [AgentRecSize]
      mul esi
      mov edi, [AgentsAddr]
      add edi, eax
      mov dword[edi], esi ; agent number (because we have indexing from zero, agents size will next agent id (used ONLY DURING GENERATION, before any agent died) )

      mov eax, [FieldSize]  ; may be optimised mb
      mul [FieldSize]
      sub eax, ecx
      mov dword[edi + AGENT_COORDS_OFFSET], eax ; curr coords
      mov word[edi + AGENT_ENERGY_OFFSET], AgentInitEnergy
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
  mov [AgentNextIndex], eax
  ret  
endp