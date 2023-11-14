
; BP registor is used inside!!!
proc AgentMoveTop uses esi edi ebx edx, ind
  mov esi, [AgentsAddr]
  mov eax, [ind]
  mul [AgentRecSize]
  add esi, eax

  mov edi, [FieldSize]
  cmp [esi + AGENT_COORDS_OFFSET], edi
  jb .finish; agent is at top line - so skip move, but energy is decreased

  ; check that target cell empty
  neg edi
  mov eax, edi
  mov ebx, [FieldAddr]
  mov eax, [esi + AGENT_COORDS_OFFSET]
  shl eax, 2 
  add ebx, eax
  test dword[ebx + edi * FieldCellSize], FIELD_AGENT_STATE
  jnz .finish ; cell is busy
  
  mov eax, 0xFFFFFFFF
  xor eax, FIELD_AGENT_STATE
  and dword[ebx], eax

  mov eax, [esi + AGENT_COORDS_OFFSET] ; saving old coords for buf move
  ; edi is already negative
  add [esi + AGENT_COORDS_OFFSET], edi ; moving agent up
  
  movzx edx, word[esi + AGENT_ENERGY_OFFSET]
  stdcall BufMoveAgent, eax, [esi + AGENT_COORDS_OFFSET], edx

  ; edi is already negative
  or dword[ebx + edi * FieldCellSize], FIELD_AGENT_STATE

  mov eax, [AgentEnergyToMove]
  sub dword[esi + AGENT_ENERGY_OFFSET], eax

  test dword[ebx + edi * FieldCellSize], FIELD_FOOD_STATE ; test is it food cell
  jz .finish
    stdcall FeedAgent, [ind], [esi + AGENT_COORDS_OFFSET]

  .finish:
  
  ret
endp

proc AgentMoveDown uses esi edi ebx edx, ind
  mov esi, [AgentsAddr]
  mov eax, [ind]
  mul [AgentRecSize]
  add esi, eax

  mov edi, [FieldSize]
  mov eax, edi
  mul eax
  sub eax, edi ; getting last line start position
  cmp [esi + AGENT_COORDS_OFFSET], eax
  jge .finish; agent is at bottom line - so skip move, but energy is decreased

  ; check that target cell empty
  mov ebx, [FieldAddr]
  mov eax, [esi + AGENT_COORDS_OFFSET]
  shl eax, 2
  add ebx, eax
  test dword[ebx + edi * FieldCellSize], FIELD_AGENT_STATE
  jnz .finish ; cell is busy

  mov eax, 0xFFFFFFFF
  xor eax, FIELD_AGENT_STATE
  and dword[ebx], eax

  mov eax, [esi + AGENT_COORDS_OFFSET] ; saving old coords for buf move
  
  add [esi + AGENT_COORDS_OFFSET], edi ; moving agent down
  
  movzx edx, word[esi + AGENT_ENERGY_OFFSET]
  stdcall BufMoveAgent, eax, [esi + AGENT_COORDS_OFFSET], edx
  

  or dword[ebx + edi * FieldCellSize], FIELD_AGENT_STATE

  mov eax, [AgentEnergyToMove]
  sub word[esi + AGENT_ENERGY_OFFSET], ax

  test dword[ebx + edi * FieldCellSize], FIELD_FOOD_STATE ; test is it food cell
  jz .finish
    stdcall FeedAgent, [ind], [esi + AGENT_COORDS_OFFSET]

  .finish:
  
  ret
endp

proc AgentMoveRight uses esi edi ebx edx, ind
  mov esi, [AgentsAddr]
  mov eax, [ind]
  mul [AgentRecSize]
  add esi, eax

  
  mov eax, [esi + AGENT_COORDS_OFFSET]
  add eax, 1
  xor edx, edx
  div [FieldSize]
  cmp edx, 0  ; check that (coords + 1) // FieldSize == 0 (in this case agent is at right corner)
  je .finish; agent is at right edge - so skip move, but energy is decreased

  ; check that target cell empty
  mov ebx, [FieldAddr]
  mov eax, [esi + AGENT_COORDS_OFFSET]
  shl eax, 2
  add ebx, eax
  test dword[ebx + FieldCellSize], FIELD_AGENT_STATE
  jnz .finish ; cell is busy

  mov eax, 0xFFFFFFFF
  xor eax, FIELD_AGENT_STATE
  and dword[ebx], eax

  mov eax, [esi + AGENT_COORDS_OFFSET] ; saving old coords for buf move
  
  inc dword[esi + AGENT_COORDS_OFFSET] ; moving agent to right
  
  movzx edx, word[esi + AGENT_ENERGY_OFFSET]
  stdcall BufMoveAgent, eax, [esi + AGENT_COORDS_OFFSET], edx

  or dword[ebx + FieldCellSize], FIELD_AGENT_STATE

  mov eax, [AgentEnergyToMove]
  sub word[esi + AGENT_ENERGY_OFFSET], ax

  test dword[ebx + FieldCellSize], FIELD_FOOD_STATE ; test is it food cell
  jz .finish
    stdcall FeedAgent, [ind], [esi + AGENT_COORDS_OFFSET]

  .finish:

  ret
endp

proc AgentMoveLeft uses esi edi ebx edx, ind
  mov esi, [AgentsAddr]
  mov eax, [ind]
  mul [AgentRecSize]
  add esi, eax


  mov eax, [esi + AGENT_COORDS_OFFSET]
  xor edx, edx
  div [FieldSize]
  cmp edx, 0  ; check that (coords + 1) // FieldSize == 0 (in this case agent is at right corner)
  je .finish; agent is at left edge - so skip move, but energy is decreased

  ; check that target cell empty
  mov ebx, [FieldAddr]
  mov eax, [esi + AGENT_COORDS_OFFSET]
  shl eax, 2
  add ebx, eax
  test dword[ebx - FieldCellSize], FIELD_AGENT_STATE
  jnz .finish ; cell is busy

  mov eax, 0xFFFFFFFF
  xor eax, FIELD_AGENT_STATE
  and dword[ebx], eax
    
  mov eax, [esi + AGENT_COORDS_OFFSET] ; saving old coords for buf move

  dec dword[esi + AGENT_COORDS_OFFSET] ; moving agent to left
  
  movzx edx, word[esi + AGENT_ENERGY_OFFSET]
  stdcall BufMoveAgent, eax, [esi + AGENT_COORDS_OFFSET], edx
  
  or dword[ebx - FieldCellSize], FIELD_AGENT_STATE

  mov eax, [AgentEnergyToMove]
  sub word[esi + AGENT_ENERGY_OFFSET], ax

  test dword[ebx - FieldCellSize], FIELD_FOOD_STATE ; test is it food cell
  jz .finish
    stdcall FeedAgent, [ind], [esi + AGENT_COORDS_OFFSET]

  .finish:
  
  ret
endp

proc AgentSleep, ind
  ret
endp


; coords - coords with food
proc FeedAgent uses ecx esi edi ebx, AgentI, coords
  ; removing food flag from field cell
  mov edi, [FieldAddr]
  mov eax, [coords]
  shl eax, 2
  add edi, eax
  xor dword[edi], FIELD_FOOD_STATE

  mov eax, dword[edi]
  and eax, FIELD_SAFE_MASK
  push eax
  mov edi, [FoodAddr]
  mul [FoodRecSize]
  add edi, eax
  
  FoundEl:
    ; getting food amount
    mov ebx, [edi + FOOD_AMOUNT_OFFSET] ; in edi already have addr of curr food       
    
    ; getting agents addr
    mov edi, [AgentsAddr]
    mov eax, [AgentI]
    mul dword[AgentRecSize] 
    add edi, eax

    add word [edi + AGENT_ENERGY_OFFSET], bx
    pop eax
    stdcall removeVecItem, [FoodAddr], FoodSize, [FoodRecSize], FOOD_COORDS_OFFSET, eax
  .Exit:

  ret
endp

proc AgentClone uses ecx esi edi ebx edx, ind
  mov [AgentClonedSuccessfully], 1
  ; getting agent addr in agents vector
  mov esi, [AgentsAddr]
  mov eax, [ind]

  mul [AgentRecSize]
  add esi, eax
  
  xor ebx, ebx ; amount of possibles directions in stack

  ; move clone to TOP
  ; edi will store new agent coords
  mov edi, [esi + AGENT_COORDS_OFFSET]
  sub edi, [FieldSize]
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
  div [FieldSize]
  cmp edx, 0
  jz @F ; skip if in right border
    inc edi
    inc ebx
    push edi ; save coords to check
  @@:


  ; move clone to BOTTOM
  mov edi, [esi + AGENT_COORDS_OFFSET]
  add edi, [FieldSize]
  mov eax, [FieldSize]
  mul eax
  cmp edi, eax
  jae @F
    inc ebx
    push edi ; save coords to check
  @@:


  ; move clone to LEFT
  mov edi, [esi + AGENT_COORDS_OFFSET]
  xor edx, edx
  mov eax, edi
  div [FieldSize]
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
  xor edx, edx ; flag, was agent found or not
  checkIsCellEmpty:
    pop edi
    mov ebx, [FieldAddr]
    test dword[ebx + edi * FieldCellSize], FIELD_AGENT_STATE
    jz .FoundPlace
    jmp @F
    .FoundPlace:
      mov edx, 1
      dec ecx
      cmp ecx, 0
      je .StartCloning ; if there were only one coords, they are already extracted
      .ExtractAll:
        pop eax ; getting other coords from stack (deleting just)
      loop .ExtractAll
      jmp .StartCloning
    @@:  
  loop checkIsCellEmpty

  cmp edx, 1
  jne TerminateCloning

  .StartCloning:  

    movzx eax, word[esi + AGENT_COORDS_OFFSET]
    movzx edx, word[esi + AGENT_ENERGY_OFFSET]

    mov eax, [AgentEnergyToClone]
    sub word[esi + AGENT_ENERGY_OFFSET], ax
    
    ; edi stores coords of new agent 
    mov eax, [AgentsSize]
    cmp eax, [AgentsCapacity]
    jae TerminateCloning ; not enough space for new agent
    
    mov ebx, [FieldAddr]
    mov eax, [esi + AGENT_COORDS_OFFSET]
    shl eax, 2
    or dword[ebx + edi * FieldCellSize], FIELD_AGENT_STATE ; updated new cell

    
    
    ; updating agent energy (it will be splitted between it and clone)
    movzx eax, word[esi + AGENT_ENERGY_OFFSET]
    shr eax, 1
    mov word[esi + AGENT_ENERGY_OFFSET], ax
    ; because of movsb energy will be saved to clone too

    movzx ebx, word[esi + AGENT_COORDS_OFFSET]
    stdcall BufCloneCell, ebx, edi, eax

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
    mov [edi + AGENT_COORDS_OFFSET], ebx ; changing coords
    mov word[edi + AGENT_CURR_INSTR_OFFSET], 0

    mov esi, [FieldAddr]
    test dword[esi + ebx * FieldCellSize], FIELD_FOOD_STATE ; checking is it food cell
    jz @F 
      stdcall FeedAgent, [AgentsSize], ebx
    @@:

    ; writing new agent id to field
    and dword[esi + ebx * FieldCellSize], 1100_0000_0000_0000_0000_0000_0000_0000b
    mov eax, [AgentsSize]
    or dword[esi + ebx * FieldCellSize], eax
    movzx ecx, word[edi + AGENT_INSTR_NUM_OFFSET]
    xor ebx, ebx
    .CheckMutation:
      stdcall RandInt, 100
      cmp eax, [AgentMutationOdds]
      ja .NextAgent
        
        ; generating new instruction
        stdcall RandInt, [AgentTaskMaxInd]
        mov byte[ebx + edi + AGENT_INSTR_VEC_OFFSET], al

      .NextAgent:
      inc ebx
    loop .CheckMutation

    inc [AgentsSize]
  jmp @F
  TerminateCloning:
    mov [AgentClonedSuccessfully], 0

  @@:

  ret
endp