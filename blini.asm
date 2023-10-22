format PE GUI 4.0
entry start

section '.data' data readable writeable
  ; Game stuff
  TotalTacts dd ?
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
  AgentInitEnergy = 21
  AgentTaskMaxInd dd 3
  AgentTasks dd AgentMoveTop, AgentMoveRight, AgentMoveDown, AgentMoveLeft, AgentSleep, 6 
  AgentsCapacity dd ?
  AgentsSize dd 0
  AgentsAddr dd ?
  AgentEnergyToMove = 20
  AgentEnergyToClone = 100
  AgentMinEnergyToClone = 400
  AgentNextIndex dd 0
  AgentMutationOdds dd 10 ; in percents
    
  ; food info
  FoodRecSize dd 6
  FOOD_COORDS_OFFSET = 0 ; 4B
  FOOD_AMOUNT_OFFSET = 4 ; 2B
  FoodMaxAmount dd 200
  FoodCapacity dd ?
  FoodSize dd 0
  FoodAddr dd ?


  allocFailedMsg db 'allocation failed', 0
  deathMsg db 'EveryoneEveryoneEveryoneEveryoneEveryone died', 0
  deathMsg2 db 'Everyone died', 0
  

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

  push [FoodSize]
  push [AgentsSize]

  stdcall startGame


; just to print total number of tacts
    xor edx, edx
    mov ebx, 10
    mov eax, ebp
    xor edi, edi
    mov esi, deathMsg
    

    xor ecx, ecx
    @@:

        inc ecx
        inc esi

        div ebx
        add edx, '0'
        mov [esi], edx
        xor edx, edx
    

        cmp eax, 0
        
    jnz @b

    inc esi
    mov dword[esi], ' '
    pop eax
    

    xor ecx, ecx
    @@:

        inc ecx
        inc esi

        div ebx
        add edx, '0'
        mov [esi], edx
        xor edx, edx
    

        cmp eax, 0
        
    jnz @b

inc esi
    mov dword[esi], ' '
    pop eax
    

    xor ecx, ecx
    @@:

        inc ecx
        inc esi

        div ebx
        add edx, '0'
        mov [esi], edx
        xor edx, edx
    

        cmp eax, 0
        
    jnz @b
  invoke MessageBox, 0, deathMsg, deathMsg2, MB_OK
  ; cleaning up
  invoke HeapFree, [HeapHandle], 0, [fieldAddr]
  invoke ExitProcess, 0
  ret
endp


  include 'field.asm'
  include 'assistive.asm'
  include 'agents.asm'


proc startGame
  xor ebp, ebp ; tact counter

  gameLoop:
    mov ecx, [AgentsSize]
    cmp ecx, 0
    jle GameOver ; all agents died
    xor esi, esi
    mov edi, [AgentsAddr]
    AgentsVecLoop:
      
      ; CHECK ROBOT ENERGY
      movzx eax, word[edi + AGENT_ENERGY_OFFSET]
      cmp eax, 0
      jg @F
        mov eax, [AgentRecSize]
        mul esi
        mov ebx, eax
        xor byte[ebx + edi], FIELD_AGENT_STATE
        stdcall removeVecItem, [AgentsAddr], AgentsSize, [AgentRecSize], AGENT_COORDS_OFFSET, esi
        dec esi ; decrementing cause 1 agent is gone, but he was replaced with last one in agent vector, so need to process him
        sub edi, [AgentRecSize] ; same as esi
        jmp NextAgent
      @@:

      ; cmp eax, AgentMinEnergyToClone
      ; jb ContinueExecution

      ; ; cloning agent
      ; stdcall AgentClone, esi
      ; jmp NextAgent

      ContinueExecution: 
        dec word[edi + AGENT_ENERGY_OFFSET] ; decrementing energy
        movzx ebx, word[edi + AGENT_CURR_INSTR_OFFSET] ; got curr instruction(2B)
        movzx ebx, byte[edi + ebx + AGENT_INSTR_VEC_OFFSET] ; got instruction index (in array of functions to call)
        
        ; checking is it move instruction
        cmp ebx, 4
        jge @F
        ; checking does agent has enough energy to move
        cmp word[edi + AGENT_ENERGY_OFFSET], AgentEnergyToMove
        jge @F
        ; if not - skipping move
        jmp skipMove
        @@:
        stdcall dword[AgentTasks + ebx * 4], esi ; calling instruction
        skipMove:

        ; switch to next instruction
        inc word[edi + AGENT_CURR_INSTR_OFFSET]
        movzx ebx, word[edi + AGENT_CURR_INSTR_OFFSET]
        cmp bx, word[edi + AGENT_INSTR_NUM_OFFSET] ; if instr i < MAX_I - continut
        jb NextAgent
        jl NextAgent
        mov word[edi + AGENT_CURR_INSTR_OFFSET], 0

        NextAgent:
          add edi, [AgentRecSize]
          inc esi

        dec ecx
        cmp ecx, 0
        je .stopAgentLoop
        jmp AgentsVecLoop

        .stopAgentLoop:

        inc ebp
    jmp gameLoop

  GameOver:
  mov [TotalTacts], ebp
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
