format PE GUI 4.0
entry start

section '.data' data readable writeable
  HeapHandle dd ?
  TotalAllocSize dd ?
  ; field data
  fieldSize dd 1024
  fieldCellSize dd 1
  fieldAddr dd ?
  FIELD_AGENT_STATE = 0100_0000b
  FIELD_FOOD_STATE = 1000_0000b

  ; agents vec data
  AgentRecSize dd 22
  AGENT_COORDS_OFFSET = 4 ; 4B
  AGENT_ENERGY_OFFSET = 8 ; 2B
  AGENT_CURR_INSTR_OFFSET = 10 ; 2B
  AGENT_INSTR_NUM_OFFSET = 12  ; 2B
  AGENT_INSTR_VEC_OFFSET = 14 ; B[]
  AGENT_MAX_INSTRUCTIONS_N = 8 ; 
  AgentInitEnergy = 25
  TasksAmount dd 3
  AgentTasks dd AgentMoveTop, AgentMoveDown, AgentMoveLeft, AgentMoveRight, AgentSleep, 6 
  AgentsCapacity dd ?
  AgentsSize dd 0
  AgentsAddr dd ?
    
  ; food info
  FoodRecSize dd 6
  FOOD_COORDS_OFFSET = 0 ; 4B
  FOOD_AMOUNT_OFFSET = 4 ; 2B
  FoodMaxAmount dd 50
  FoodCapacity dd ?
  FoodSize dd 0
  FoodAddr dd ?

  allocFailedMsg db 'allocation failed', 0
  deathMsg db 'Everyone died', 0

section '.text' code readable executable
  include 'win32a.inc'
proc start
  stdcall getFieldSize, [fieldSize] ; got field size
  mov [TotalAllocSize], eax
  ; assuming that maximum amount of agents is n * n/2, for food same
  mov eax, [fieldSize]
  mul [fieldSize]
  ; shr eax, 1

  ; saving capacity
  mov [FoodCapacity], eax
  mov [AgentsCapacity], eax

  ; getting amount of bytes
  mov edx, [AgentRecSize]
  add edx, [FoodRecSize]
  mul edx ; got size for agents, food
  add [TotalAllocSize], eax ; total size
  stdcall allocMem, [TotalAllocSize], HeapHandle, fieldAddr

  ; calculating AgentsAddr
  mov ebx, [fieldAddr]
  stdcall getFieldSize, [fieldSize]
  add ebx, eax
  mov [AgentsAddr], ebx

  ; calculating FoodAddr
  mov eax, [fieldSize]
  mul [fieldSize]
  ; shr eax, 1
  mul [AgentRecSize]
  add ebx, eax
  mov [FoodAddr], ebx 

  stdcall fillField

  stdcall startGame

  invoke MessageBox, 0, allocFailedMsg, deathMsg, MB_OK
  ; cleaning up
  invoke HeapFree, [HeapHandle], 0, [fieldAddr]
  invoke ExitProcess, 0
  ret
endp
 
proc startGame
  xor ebp, ebp ; tact counter

  gameLoop:
    mov ecx, [AgentsSize]
    cmp ecx, 0
    jle GameOver ; all agents died
    xor esi, esi
    AgentsVecLoop:
      mov edi, [AgentsAddr]
      mov eax, esi
      mul dword[AgentRecSize] 
      add edi, eax ; got current agent addr

      ; CHECK ROBOT ENERGY
      movzx eax, word[edi + AGENT_ENERGY_OFFSET]
      cmp eax, 0
      jg @F
        stdcall removeVecItem, [AgentsAddr], AgentsSize, [AgentRecSize], AGENT_COORDS_OFFSET, esi
        dec esi ; decrementing cause 1 agent is gone, but he was replaced with last one in agent vector, so need to process him
        jmp Continue
      @@:
      movzx ebx, word[edi + AGENT_CURR_INSTR_OFFSET] ; got curr instruction(2B)
      movzx ebx, byte[edi + ebx + AGENT_INSTR_VEC_OFFSET] ; got instruction index (in array of functions to call)
      stdcall dword[AgentTasks + ebx * 4], esi ; calling instruction

      ; switch to next instruction
      inc word[edi + AGENT_CURR_INSTR_OFFSET]
      movzx ebx, word[edi + AGENT_CURR_INSTR_OFFSET]
      cmp bx, word[edi + AGENT_INSTR_NUM_OFFSET] ; if instr i < MAX_I - continut
      jb Continue
      jl Continue
      mov word[edi + AGENT_CURR_INSTR_OFFSET], 0

      Continue:
        inc esi
      loop AgentsVecLoop
      inc ebp
    jmp gameLoop

  GameOver:
  ret
endp

; BP registor is used inside!!!
proc AgentMoveTop uses esi edi ebx ebp, ind
  mov esi, [AgentsAddr]
  mov eax, [ind]
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

  .decrEnergy:
  dec word[esi + AGENT_ENERGY_OFFSET]
  
  ret
endp
proc AgentMoveDown uses esi edi ebx ebp, ind
  mov esi, [AgentsAddr]
  mov eax, [ind]
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

  .decrEnergy:
  dec word[esi + AGENT_ENERGY_OFFSET]
  
  ret
endp

proc AgentMoveRight uses esi edi ebx ebp, ind
  mov esi, [AgentsAddr]
  mov eax, [ind]
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

  .decrEnergy:
  dec word[esi + AGENT_ENERGY_OFFSET]

  ret
endp

proc AgentMoveLeft uses esi edi ebx ebp, ind
  mov esi, [AgentsAddr]
  mov eax, [ind]
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

  .decrEnergy:
  dec word[esi + AGENT_ENERGY_OFFSET]
  
  ret
endp

proc AgentSleep, ind

  ret
endp


; generates field with food, with agents and so on
proc fillField
  ; get emount of cells to generate
  mov eax, [fieldSize] 
  mul [fieldSize]

  xor ebx, ebx
  xor esi, esi
  mov ecx, eax
  loopStart:
    rdrand ax
    
    ; cmp al, 128
    ; jb EmptyCell
    ; cmp al, 200
    ; jb Food
    jmp Agent
  
    EmptyCell:
      mov esi, [fieldAddr]
      mov byte[esi + ebx], 0
      jmp @F
    Food:
      ; chech is there enough memory
      mov eax, [FoodCapacity]
      cmp eax, [FoodSize]
      jle EmptyCell 

      mov ax, FIELD_FOOD_STATE

      ; food cell - oldest bit is 1
      mov esi, [fieldAddr]
      mov byte[esi + ebx], al      


      mov edi, [FoodAddr]
      mov eax, [FoodSize]
      mul [FoodRecSize]
      add edi, eax
      mov eax, [fieldSize]  ; may be optimised mb
      mul [fieldSize]
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
      mov esi, [fieldAddr]
      mov byte[esi + ebx], al


      mov esi, [AgentsSize]
      mov eax, [AgentRecSize]
      mul esi
      mov edi, [AgentsAddr]
      add edi, eax
      mov dword[edi], esi ; agent number (because we have indexing from zero, agents size will next agent id (used ONLY DURING GENERATION, before any agent died) )

      mov eax, [fieldSize]  ; may be optimised mb
      mul [fieldSize]
      sub eax, ecx
      mov dword[edi + AGENT_COORDS_OFFSET], eax ; curr coords
      mov word[edi + AGENT_ENERGY_OFFSET], AgentInitEnergy
      mov word[edi + AGENT_CURR_INSTR_OFFSET], 0

      mov eax, AGENT_MAX_INSTRUCTIONS_N ; used to not have 0 instructions
      dec eax
      stdcall RandInt, eax
      inc ax
      mov word[edi + AGENT_INSTR_NUM_OFFSET], ax 
      push ecx
      mov ecx, eax
      xor ebp, ebp ; curr instruction
      RandInstruction:
        stdcall RandInt, [TasksAmount]
        mov byte[ebp + edi + AGENT_INSTR_VEC_OFFSET], al
        inc ebp
      loop RandInstruction
      pop ecx

      inc dword[AgentsSize]
      jmp @F
    
  @@:
    add ebx, 1
    dec ecx
    cmp ecx, 0
    jz stopLoop
    jmp loopStart 
  stopLoop:
  ret  
endp

; eax - return new rand value up to maxVal
proc RandInt uses ecx ebx edx, maxVal 
    xor eax, eax
    rdrand ax
    mul word[maxVal]
    mov ebx, eax
    movzx eax, dx
    shl eax, 16
    add eax, ebx
    ; in eax - value * NewMax

    xor edx, edx
    mov ecx, 0x00_00_FF_FF 
    div ecx
    ret 
endp

; Allocate required amount of memory (memSize) for field. Stores heapHandle in HeapHandle
proc allocMem uses esi edx, memSize, PHeapHandle, PbufAddr
  ; getting heap addr
  invoke GetProcessHeap
  mov esi, [PHeapHandle] ; got addr of HeapHandle
  mov [esi], eax
  ; alloc memory for field
  invoke HeapAlloc, eax, 0, [memSize]
  mov esi, [PbufAddr] ; got addr of buf addr
  mov [esi], eax
  
  ; if ax is zero -- allocation failed
  test eax, eax
  jz .alloc_failed
  jmp .done

; displaying error msg, shutting down
.alloc_failed:
  invoke MessageBox, 0, allocFailedMsg, allocFailedMsg, MB_OK
  invoke ExitProcess, 0
  
.done:
  ret
endp


proc removeVecItem uses esi edi ecx ebp ebx, Addr, PSize, ItemSize, CoordsOffset, ind
    mov edi, [Addr]
    mov eax, [ind]
    mul dword[ItemSize] 
    add edi, eax ; got delete agent addr

    mov ebx, [CoordsOffset]
    mov esi, [edi + ebx] ; coords of item
    mov ebx, [fieldAddr]

    ; NEED TO BE FIXED IN THE FUTURE
    mov byte[ebx + esi], 0 ; clear game field
    
    mov eax, [PSize]
    mov eax, [eax]
    cmp eax, 1
    jne @F
      jmp finished
    @@:
    dec eax ; cause indexes from zero
    cmp eax, [ind]
    jne @F
      jmp finished
    @@:
      mov esi, [Addr]
      mov eax, [PSize]
      mov eax, [eax]
      dec eax ; got index
      mul dword[ItemSize] 
      add esi, eax
      
      mov ecx, [ItemSize]
      rep movsb ; write last agent info into whole after removed agent

    finished:
      mov esi, [PSize]
      dec dword[esi]
  ret
endp

proc getFieldSize, size
  mov eax, [size]
  mul eax
  mul [fieldCellSize]
  ret
endp

section '.idata' import data readable writeable
  library kernel32, 'KERNEL32.DLL',\
          user32, 'USER32.DLL'

  import kernel32,\
         GetProcessHeap, 'GetProcessHeap',\
         HeapAlloc, 'HeapAlloc',\
         HeapFree, 'HeapFree',\
         ExitProcess, 'ExitProcess',\
         wsprintf, 'wsprintfA',\
         msvcrt, 'msvcrt.dll',\
         GetTickCount, 'GetTickCount'

  import user32,\
         MessageBox, 'MessageBoxA'
