format PE GUI 4.0
entry start

section '.data' data readable writeable
  HeapHandle dd ?
  TotalAllocSize dd ?
  ; field data
  fieldSize dd 2
  fieldCellSize dd 1
  fieldAddr dd ?

  ; agents vec data
  AgentRecSize dd 22
  AGENT_COORDS_OFFSET = 4 ; 4B
  AGENT_ENERGY_OFFSET = 8 ; 2B
  AGENT_CURR_INSTR_OFFSET = 10 ; 2B
  AGENT_INSTR_NUM_OFFSET = 12  ; 2B
  AGENT_INSTR_VEC_OFFSET = 14 ; B[]
  AGENT_MAX_INSTRUCTIONS_N = 8 ; +1 instruction
  AgentInitEnergy = 25
  TasksAmount dd 6
  AgentTasks dd 1, 2, 3, 4, 5, 6 ; there will be pointers to instruction functions
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

section '.text' code readable executable
  include 'win32a.inc'


proc start
  stdcall getFieldSize, [fieldSize] ; got field size
  mov [TotalAllocSize], eax
  ; assuming that maximum amount of agents is n * n/2, for food same
  mov eax, [fieldSize]
  mul [fieldSize]
  shr eax, 1

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
  shr eax, 1
  mul [AgentRecSize]
  add ebx, eax
  mov [FoodAddr], ebx 

  stdcall fillField

  stdcall startGame

  ; cleaning up
  invoke HeapFree, [HeapHandle], 0, [TotalAllocSize]
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
      @@:
      mov ebx, dword[edi + AGENT_CURR_INSTR_OFFSET] ; got curr instruction(2B), total instructions amount(2B)
      shr ebx, 16
      movzx ebp, byte[edi + ebx + AGENT_INSTR_VEC_OFFSET] ; got instruction index

      stdcall dword[AgentTasks + ebp * 4] ; calling instruction

      ; switch to next instruction
      inc bx
      cmp bx, word[edi + AGENT_INSTR_NUM_OFFSET]
      jge ReturnToFirstInstruction
        inc word[edi + AGENT_CURR_INSTR_OFFSET]
      ReturnToFirstInstruction:
        mov word[edi + AGENT_CURR_INSTR_OFFSET], 0

      inc esi
      loop AgentsVecLoop

    jmp gameLoop

  GameOver:
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
    call rdrandAX
    
    cmp al, 128
    jb EmptyCell
    cmp al, 200
    jb Food
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

      mov al, 1000_0000b

      ; food cell - oldest bit is 1
      mov esi, [fieldAddr]
      mov byte[esi + ebx], al      
     
      mov edi, [FoodAddr]
      mov eax, [fieldSize]  ; may be optimised mb
      mul [fieldSize]
      sub eax, ecx
      mov dword[edi + FOOD_COORDS_OFFSET], eax ; curr coords
      stdcall RandInt, [FoodMaxAmount]
      mov word[edi + FOOD_AMOUNT_OFFSET], ax ; save food amount
      jmp @F

    Agent:

      ; if agents vector is filed, skipping it
      mov eax, [AgentsCapacity]
      cmp eax, [AgentsSize]
      jle EmptyCell

      ; filling cell in game field and then agents vector
      xor eax, eax
      add al, 0100_0000b

      ; agent cell - pre oldest bit is 1
      mov esi, [fieldAddr]
      mov byte[esi + ebx], al


      mov esi, [AgentsSize]
      mov eax, [AgentRecSize]
      mul esi
      mov edi, [AgentsAddr]
      add edi, eax
      mov dword[edi], esi ; agent number

      mov eax, [fieldSize]  ; may be optimised mb
      mul [fieldSize]
      sub eax, ecx
      mov dword[edi + AGENT_COORDS_OFFSET], eax ; curr coords
      mov word[edi + AGENT_ENERGY_OFFSET], AgentInitEnergy
      mov word[edi + AGENT_CURR_INSTR_OFFSET], 0
      stdcall RandInt, AGENT_MAX_INSTRUCTIONS_N
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

rdrandAX:
  rdrand ax
  ret
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


proc removeVecItem, Addr, PSize, ItemSize, CoordsOffset, ind
    mov edi, [Addr]
    mov eax, [ind]
    mul dword[ItemSize] 
    add edi, eax ; got delete agent addr

    mov ebp, [CoordsOffset]
    mov esi, [edi + ebp] ; coords of item
    mov ebx, [fieldAddr]
    mov dword[ebx + esi * 4], 0 ; clear game field
    
    mov eax, [PSize]
    mov eax, [eax]
    cmp eax, 1
    jne @F
      jmp finished
    @@:
    inc eax ; cause indexes from zero
    cmp eax, [ind]
    jne @F
      jmp finished
    @@:
      mov esi, [Addr]
      mov eax, [PSize]
      mov eax, [eax]
      dec eax ; got index
      mul dword[ItemSize] 
      mov esi, eax
      
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
