
; BP registor is used inside!!!
proc AgentMoveTop uses esi edi ebx ebp, ind
  mov esi, [AgentsAddr]
  mov eax, [ind]
  mov ebx, eax
  ; DON'T TOUCH EBX ANYMORE
  mul [AgentRecSize]
  add esi, eax

  mov edi, [fieldSize]
  cmp [esi + AGENT_COORDS_OFFSET], edi
  jb .finish; agent is at top line - so skip move, but energy is decreased

  ; check that target cell empty
  neg edi
  mov ebp, [fieldAddr]
  add ebp, [esi + AGENT_COORDS_OFFSET]
  test byte[ebp + edi], FIELD_AGENT_STATE
  jnz .finish ; cell is busy
  
  mov al, 0xFF
  xor al, FIELD_AGENT_STATE
  and byte[ebp], al

  ; edi is already negative
  add [esi + AGENT_COORDS_OFFSET], edi ; moving agent up
  
  ; edi is already negative
  or byte[ebp + edi], FIELD_AGENT_STATE

  sub word[esi + AGENT_ENERGY_OFFSET], AgentEnergyToMove

  test byte[ebp + edi], FIELD_FOOD_STATE ; test is it food cell
  jz .finish
    stdcall FeedAgent, ebx, [esi + AGENT_COORDS_OFFSET]

  .finish:
  
  ret
endp

proc AgentMoveDown uses esi edi ebx ebp, ind
  mov esi, [AgentsAddr]
  mov eax, [ind]
  mov ebx, eax
  ; DON'T TOUCH EBX ANYMORE
  mul [AgentRecSize]
  add esi, eax

  mov edi, [fieldSize]
  mov eax, edi
  mul eax
  sub eax, edi ; getting last line start position
  cmp [esi + AGENT_COORDS_OFFSET], edi
  jge .finish; agent is at bottom line - so skip move, but energy is decreased

  ; check that target cell empty
  mov ebp, [fieldAddr]
  add ebp, [esi + AGENT_COORDS_OFFSET]
  test byte[ebp + edi], FIELD_AGENT_STATE
  jnz .finish ; cell is busy

  mov al, 0xFF
  xor al, FIELD_AGENT_STATE
  and byte[ebp], al
  add [esi + AGENT_COORDS_OFFSET], edi ; moving agent down
  or byte[ebp + edi], FIELD_AGENT_STATE

  sub word[esi + AGENT_ENERGY_OFFSET], AgentEnergyToMove

  test byte[ebp + edi], FIELD_FOOD_STATE ; test is it food cell
  jz .finish
    stdcall FeedAgent, ebx, [esi + AGENT_COORDS_OFFSET]

  .finish:
  
  ret
endp

proc AgentMoveRight uses esi edi ebx ebp, ind
  mov esi, [AgentsAddr]
  mov eax, [ind]
  mov ebx, eax
  ; DON'T TOUCH EBX ANYMORE
  mul [AgentRecSize]
  add esi, eax

  
  mov eax, [esi + AGENT_COORDS_OFFSET]
  add eax, 1
  xor edx, edx
  div [fieldSize]
  cmp edx, 0  ; check that (coords + 1) // fieldSize == 0 (in this case agent is at right corner)
  je .finish; agent is at right edge - so skip move, but energy is decreased

  ; check that target cell empty
  mov ebp, [fieldAddr]
  add ebp, [esi + AGENT_COORDS_OFFSET]
  test byte[ebp + 1], FIELD_AGENT_STATE
  jnz .finish ; cell is busy

  mov al, 0xFF
  xor al, FIELD_AGENT_STATE
  and byte[ebp], al
  inc dword[esi + AGENT_COORDS_OFFSET] ; moving agent to right
  or byte[ebp + 1], FIELD_AGENT_STATE

  sub word[esi + AGENT_ENERGY_OFFSET], AgentEnergyToMove

  test byte[ebp + 1], FIELD_FOOD_STATE ; test is it food cell
  jz .finish
    stdcall FeedAgent, ebx, [esi + AGENT_COORDS_OFFSET]

  .finish:

  ret
endp

proc AgentMoveLeft uses esi edi ebx ebp, ind
  mov esi, [AgentsAddr]
  mov eax, [ind]
  mov ebx, eax
  ; DON'T TOUCH EBX ANYMORE
  mul [AgentRecSize]
  add esi, eax


  mov eax, [esi + AGENT_COORDS_OFFSET]
  xor edx, edx
  div [fieldSize]
  cmp edx, 0  ; check that (coords + 1) // fieldSize == 0 (in this case agent is at right corner)
  je .finish; agent is at left edge - so skip move, but energy is decreased

  ; check that target cell empty
  mov ebp, [fieldAddr]
  add ebp, [esi + AGENT_COORDS_OFFSET]
  test byte[ebp - 1], FIELD_AGENT_STATE
  jnz .finish ; cell is busy

  mov al, 0xFF
  xor al, FIELD_AGENT_STATE
  and byte[ebp], al
  dec dword[esi + AGENT_COORDS_OFFSET] ; moving agent to left
  or byte[ebp - 1], FIELD_AGENT_STATE

  sub word[esi + AGENT_ENERGY_OFFSET], AgentEnergyToMove

  test byte[ebp - 1], FIELD_FOOD_STATE ; test is it food cell
  jz .finish
    stdcall FeedAgent, ebx, [esi + AGENT_COORDS_OFFSET]

  .finish:
  
  ret
endp

proc AgentSleep, ind
  ret
endp


; coords - coords with food
proc FeedAgent uses ecx esi edi ebx, AgentI, coords
  ; removing food flag from field cell
  mov edi, [fieldAddr]
  add edi, [coords]
  xor byte[edi], FIELD_FOOD_STATE

  mov ecx, [FoodSize]
  xor esi, esi
  mov edi, [FoodAddr]
  FindFoodEl:     
    mov eax, [edi + FOOD_COORDS_OFFSET]
    cmp eax, [coords] ; checking did we got to correct record
    je FoundEl      

    add edi, [FoodRecSize]
    inc esi
  loop FindFoodEl
  jmp FoundEl.Exit ; not found food, skipping all stuff
  
  FoundEl:
    ; getting food amount
    mov ebx, [edi + FOOD_AMOUNT_OFFSET] ; in edi already have addr of curr food       
    
    ; getting agents addr
    mov edi, [AgentsAddr]
    mov eax, [AgentI]
    mul dword[AgentRecSize] 
    add edi, eax

    add word [edi + AGENT_ENERGY_OFFSET], bx

    stdcall removeVecItem, [FoodAddr], FoodSize, [FoodRecSize], FOOD_COORDS_OFFSET, esi
  .Exit:

  ret
endp

proc AgentClone uses ecx esi edi ebx edx, ind
  ; getting agent addr in agents vector
  mov esi, [AgentsAddr]
  mov eax, [ebp + 8]

  mul [AgentRecSize]
  add esi, eax
  
  xor ebx, ebx ; amount of possibles directions in stack

  ; move clone to TOP
  ; edi will store new agent coords
  mov edi, [esi + AGENT_COORDS_OFFSET]
  sub edi, [fieldSize]
  cmp edi, 0

  
  jl @F
    inc ebx
    push edi ; save coords to check
  @@:

  ; move clone to RIGHT
  mov edi, [esi + AGENT_COORDS_OFFSET]
  mov eax, edi 
  add eax, 1
  xor edx, edx
  div [fieldSize]
  cmp edx, 0
  jz @F ; skip if in right border
    inc edi
    inc ebx
    push edi ; save coords to check
  @@:


  ; move clone to BOTTOM
  mov edi, [esi + AGENT_COORDS_OFFSET]
  add edi, [fieldSize]
  stdcall getFieldSize, [fieldSize]
  cmp edi, eax
  jae @F
    inc ebx
    push edi ; save coords to check
  @@:


  ; move clone to LEFT
  mov edi, [esi + AGENT_COORDS_OFFSET]
  xor edx, edx
  mov eax, edi
  div [fieldSize]
  cmp edx, 0
  jz @F ; it's in left column, skipping
    dec edi
    inc ebx
    push edi ; save coords to check
    mov ecx, ebx
    jmp checkIsCellEmpty
  @@:
    cmp ebx, 0
    je TerminateCloning ; rejected cloning (no space to move clone to)
  
  mov ecx, ebx
  checkIsCellEmpty:
    pop edi
    mov ebx, [fieldAddr]
    test byte[ebx + edi], FIELD_AGENT_STATE
    jz .FoundPlace
    jmp @F
    .FoundPlace:
      dec ecx
      cmp ecx, 0
      je .StartCloning ; if there were only one coords, they are already extracted
      .ExtractAll:
        pop eax ; getting other coords from stack (deleting just)
      loop .ExtractAll
      jmp .StartCloning
    @@:  
  loop checkIsCellEmpty


  .StartCloning:  
    sub word[esi + AGENT_ENERGY_OFFSET], AgentEnergyToClone
    
    ; edi stores coords of new agent 
    mov eax, [AgentsSize]
    cmp eax, [AgentsCapacity]
    jae TerminateCloning ; not enough space for new agent
    
    mov ebx, [fieldAddr]
    add ebx, [esi + AGENT_COORDS_OFFSET]
    xor byte[ebx], FIELD_AGENT_STATE ; clear old cell
    sub ebx, [esi + AGENT_COORDS_OFFSET]
    or byte[ebx + edi], FIELD_AGENT_STATE ; updated new cell
    
    ; updating agent energy (it will be splitted between it and clone)
    mov eax, [esi + AGENT_ENERGY_OFFSET]
    shr eax, 1
    mov [esi + AGENT_ENERGY_OFFSET], eax
    ; because of movsb energy will be saved to clone too

    ; getting new agent addr
    ; edi stores coords of new agent
    mov ebx, edi ; backed it up
    mov eax, [AgentsSize] 
    mov edi, [AgentsAddr]
    mul [AgentRecSize]
    add edi, eax      ; got new agent address
    
    mov ecx, [AgentRecSize]
    cld
    rep movsb ; copying agent data

    sub edi, [AgentRecSize] ; got new agent addr back
    mov eax, [AgentNextIndex]
    mov [edi], eax
    mov [edi + AGENT_COORDS_OFFSET], ebx ; changing coords
    mov word[edi + AGENT_CURR_INSTR_OFFSET], 0

    mov esi, [fieldAddr]
    test byte[esi + ebx], FIELD_FOOD_STATE ; checking is it food cell
    jz @F 
      stdcall FeedAgent, [AgentsSize], ebx
    @@:
    movzx ecx, word[edi + AGENT_INSTR_NUM_OFFSET]
    xor ebx, ebx
    .CheckMutation:
      stdcall RandInt, 100
      cmp eax, AgentMutationOdds
      ja .NextAgent
        
        ; generating new instruction
        stdcall RandInt, [AgentTaskMaxInd]
        mov byte[ebx + edi + AGENT_INSTR_VEC_OFFSET], al

      .NextAgent:
      inc ebx
    loop .CheckMutation

    inc [AgentNextIndex]
    inc [AgentsSize]
  TerminateCloning:
  ret
endp