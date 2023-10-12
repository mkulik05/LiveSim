
; BP registor is used inside!!!
proc AgentMoveTop uses esi edi ebx ebp, ind
  mov esi, [AgentsAddr]
  mov eax, [ind]
  mov ebx, eax
  mul [AgentRecSize]
  add esi, eax

  mov edi, [fieldSize]
  cmp [esi + AGENT_COORDS_OFFSET], edi
  jb .decrEnergy; agent is at top line - so skip move, but energy is decreased

  ; check that target cell empty
  neg edi
  mov ebp, [fieldAddr]
  add ebp, [esi + AGENT_COORDS_OFFSET]
  test byte[ebp + edi], FIELD_AGENT_STATE
  jnz .decrEnergy ; cell is busy
  
  mov ebx, [esi + AGENT_COORDS_OFFSET]
  mov al, 0xFF
  xor al, FIELD_AGENT_STATE
  and byte[ebp], al

  ; edi is already negative
  add [esi + AGENT_COORDS_OFFSET], edi ; moving agent up
  
  ; edi is already negative
  or byte[ebp + edi], FIELD_AGENT_STATE

  sub word[esi + AGENT_ENERGY_OFFSET], AgentEnergyToMove

  test byte[ebp + edi], FIELD_FOOD_STATE ; test is it food cell
  jz .decrEnergy
    stdcall FeedAgent, ebx, [esi + AGENT_COORDS_OFFSET]

  .decrEnergy:
  dec word[esi + AGENT_ENERGY_OFFSET]
  
  ret
endp

proc AgentMoveDown uses esi edi ebx ebp, ind
  mov esi, [AgentsAddr]
  mov eax, [ind]
  mov ebx, eax
  mul [AgentRecSize]
  add esi, eax

  mov edi, [fieldSize]
  mov eax, edi
  mul eax
  sub eax, edi ; getting last line start position
  cmp [esi + AGENT_COORDS_OFFSET], edi
  jge .decrEnergy; agent is at bottom line - so skip move, but energy is decreased

  ; check that target cell empty
  mov ebp, [fieldAddr]
  add ebp, [esi + AGENT_COORDS_OFFSET]
  test byte[ebp + edi], FIELD_AGENT_STATE
  jnz .decrEnergy ; cell is busy

  mov ebx, [esi + AGENT_COORDS_OFFSET]
  mov al, 0xFF
  xor al, FIELD_AGENT_STATE
  and byte[ebp], al
  add [esi + AGENT_COORDS_OFFSET], edi ; moving agent down
  or byte[ebp + edi], FIELD_AGENT_STATE

  sub word[esi + AGENT_ENERGY_OFFSET], AgentEnergyToMove

  test byte[ebp + edi], FIELD_FOOD_STATE ; test is it food cell
  jz .decrEnergy
    stdcall FeedAgent, ebx, [esi + AGENT_COORDS_OFFSET]

  .decrEnergy:
  dec word[esi + AGENT_ENERGY_OFFSET]
  
  ret
endp

proc AgentMoveRight uses esi edi ebx ebp, ind
  mov esi, [AgentsAddr]
  mov eax, [ind]
  mov ebx, eax
  mul [AgentRecSize]
  add esi, eax

  
  mov eax, [esi + AGENT_COORDS_OFFSET]
  add eax, 1
  xor edx, edx
  div [fieldSize]
  cmp edx, 0  ; check that (coords + 1) // fieldSize == 0 (in this case agent is at right corner)
  je .decrEnergy; agent is at right edge - so skip move, but energy is decreased

  ; check that target cell empty
  mov ebp, [fieldAddr]
  add ebp, [esi + AGENT_COORDS_OFFSET]
  test byte[ebp + 1], FIELD_AGENT_STATE
  jnz .decrEnergy ; cell is busy

  mov ebx, [esi + AGENT_COORDS_OFFSET]
  mov al, 0xFF
  xor al, FIELD_AGENT_STATE
  and byte[ebp], al
  inc dword[esi + AGENT_COORDS_OFFSET] ; moving agent to right
  or byte[ebp + 1], FIELD_AGENT_STATE

  sub word[esi + AGENT_ENERGY_OFFSET], AgentEnergyToMove

  test byte[ebp + 1], FIELD_FOOD_STATE ; test is it food cell
  jz .decrEnergy
    stdcall FeedAgent, ebx, [esi + AGENT_COORDS_OFFSET]

  .decrEnergy:
  dec word[esi + AGENT_ENERGY_OFFSET]

  ret
endp

proc AgentMoveLeft uses esi edi ebx ebp, ind
  mov esi, [AgentsAddr]
  mov eax, [ind]
  mov ebx, eax
  mul [AgentRecSize]
  add esi, eax


  mov eax, [esi + AGENT_COORDS_OFFSET]
  xor edx, edx
  div [fieldSize]
  cmp edx, 0  ; check that (coords + 1) // fieldSize == 0 (in this case agent is at right corner)
  je .decrEnergy; agent is at left edge - so skip move, but energy is decreased

  ; check that target cell empty
  mov ebp, [fieldAddr]
  add ebp, [esi + AGENT_COORDS_OFFSET]
  test byte[ebp - 1], FIELD_AGENT_STATE
  jnz .decrEnergy ; cell is busy

  mov ebx, [esi + AGENT_COORDS_OFFSET]
  mov al, 0xFF
  xor al, FIELD_AGENT_STATE
  and byte[ebp], al
  dec dword[esi + AGENT_COORDS_OFFSET] ; moving agent to left
  or byte[ebp - 1], FIELD_AGENT_STATE

  sub word[esi + AGENT_ENERGY_OFFSET], AgentEnergyToMove

  test byte[ebp - 1], FIELD_FOOD_STATE ; test is it food cell
  jz .decrEnergy
    stdcall FeedAgent, ebx, [esi + AGENT_COORDS_OFFSET]
  .decrEnergy:
  dec word[esi + AGENT_ENERGY_OFFSET]
  

  ret
endp

proc AgentSleep, ind
  mov esi, [AgentsAddr]
  mov eax, [ind]
  mov ebx, eax
  mul [AgentRecSize]
  add esi, eax
  .decrEnergy:
  dec word[esi + AGENT_ENERGY_OFFSET]
  ret
endp


proc FeedAgent uses ecx esi edi ebx, AgentI, coords
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