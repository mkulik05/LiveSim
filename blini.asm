format PE GUI 4.0
entry start

include 'win32a.inc'
section '.data' data readable writeable
  ; Game stuff
  FrameDelayMs dd 1000
  TotalTacts dd ?
  HeapHandle dd ?
  TotalAllocSize dd ?
  StartTimeMs dd ?
  StopGame dd 0
  
  ; field data
  FieldSize dd 512
  FieldCellSize = 4
  FieldAddr dd ?
  FIELD_AGENT_STATE = 0100_0000_0000_0000_0000_0000_0000_0000b
  FIELD_FOOD_STATE = 1000_0000_0000_0000_0000_0000_0000_0000b

  ; agents vec data
  AgentRecSize dd 22
  AGENT_COORDS_OFFSET = 4 ; 4B
  AGENT_ENERGY_OFFSET = 8 ; 2B
  AGENT_CURR_INSTR_OFFSET = 10 ; 2B
  AGENT_INSTR_NUM_OFFSET = 12  ; 2B
  AGENT_INSTR_VEC_OFFSET = 14 ; B[]
  AGENT_MAX_INSTRUCTIONS_N = 8 
  AgentInitEnergy dd 199 ; read from file (RFF)
  AgentTaskMaxInd dd 4
  AgentTasks dd AgentMoveTop, AgentMoveRight, AgentMoveDown, AgentMoveLeft, AgentSleep, 0
  AgentsCapacity dd ?
  AgentsSize dd 0
  AgentsAddr dd ?
  AgentEnergyToMove dd 20 ; RFF
  AgentEnergyToClone dd 198 ; RFF   ; should be less then AgentMinEnergyToClone
  AgentMinEnergyToClone dd 200 ; RFF
  AgentClonedSuccessfully dd 0
  AgentNextIndex dd 0
  AgentMutationOdds dd 10 ; RFF in percents
    
  ; food info
  FoodMaxValue dd 200 ; RFF
  TimeForFoodToGrow dd 2 ; RFF; N: food grow by specified in vector value each N tacts 
  FoodGrowMaxValue dd 50 ; RFF
  FoodRecSize dd 10
  FOOD_COORDS_OFFSET = 0 ; 4B
  FOOD_AMOUNT_OFFSET = 4 ; 2B
  FOOD_MAX_AMOUNT_OFFSET = 6 ; 2B
  FOOD_GROW_VALUE_OFFSET = 8 ; 2B value, how food is incremented
  FoodMaxInitAmount dd 150  ; RFF
  FoodCapacity dd ?
  FoodSize dd 0
  FoodAddr dd ?

  ; GUI stuff
  EMPTY_COLOR = 0x00000000
  ScreenBufAddr dd 0
  ScreenWidth dd 0
  ScreenHeight dd 0
  CellSizePX dd 0
  XFieldOffset dd 0
  YFieldOffset dd 0
  _class TCHAR 'FASMWIN32', 0
  _error TCHAR 'Startup failed.', 0
  wc WNDCLASS 0, WindowProc, 0, 0, NULL, NULL, NULL, COLOR_BTNFACE + 1, NULL, _class
  hDC dd 0
  hwnd dd 0
  bmi BITMAPINFOHEADER
  msg MSG
  allocFailedMsg db 'allocation failed', 0
  deathMsg db 'EveryoneEveryoneEveryoneEveryoneEveryone died', 0
  deathMsg2 db 'Everyone died', 0
  

section '.text' code readable executable

proc start
  mov eax, FieldCellSize
  mul [FieldSize]
  mul [FieldSize]

  mov [TotalAllocSize], eax
  ; assuming that maximum amount of agents is n * n/2, for food same
  mov eax, [FieldSize]
  mul [FieldSize]
  ; shr eax, 1

  ; saving capacity
  mov [FoodCapacity], eax
  mov [AgentsCapacity], eax

  push eax
  stdcall GUIBasicInit
  pop eax

  ; getting amount of bytes
  mov edx, [AgentRecSize]
  add edx, [FoodRecSize]
  mul edx ; got size for agents, food
  add [TotalAllocSize], eax ; total size

  ; getting amount of bytes for screen buffer
  mov eax, [ScreenWidth]
  mul [ScreenHeight]
  shl eax, 2
  add [TotalAllocSize], eax

  stdcall allocMem, [TotalAllocSize], HeapHandle, FieldAddr

  ; calculating AgentsAddr
  mov ebx, [FieldAddr]
  mov eax, FieldCellSize
  mul [FieldSize]
  mul [FieldSize]
  add ebx, eax
  mov [AgentsAddr], ebx

  ; calculating FoodAddr
  mov eax, [AgentsCapacity]
  mul [AgentRecSize]
  add ebx, eax
  mov [FoodAddr], ebx 

  ; calculating Screen buf size
  mov eax, [FoodCapacity]
  mul [FoodRecSize] 
  add ebx, eax
  mov [ScreenBufAddr], ebx

  stdcall fillField

  push [FoodSize]
  push [AgentsSize]


  stdcall drawBkg
  stdcall calcCellSize ; will put result into CellSizePX constant
  stdcall calcFieldOffsets ; inits YFieldOffset and XFieldOffset
  stdcall drawField
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
  invoke HeapFree, [HeapHandle], 0, [FieldAddr]
  invoke ExitProcess, 0
  ret
endp

proc startGame
  
  xor ebp, ebp ; tact counter

  gameLoop:
    invoke GetTickCount
    mov [StartTimeMs], eax

    invoke SetDIBitsToDevice, [hDC], 0, 0, [ScreenWidth], [ScreenHeight], 0, 0, 0, [ScreenHeight], [ScreenBufAddr], bmi, 0
    stdcall ProcessWindowMsgs
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
        mov ebx, [FieldAddr]
        push edi 
        mov edi, [edi + AGENT_COORDS_OFFSET]
        xor dword[ebx + edi * FieldCellSize], FIELD_AGENT_STATE
        pop edi
        stdcall bufClearCell, [edi + AGENT_COORDS_OFFSET]
        stdcall removeVecItem, [AgentsAddr], AgentsSize, [AgentRecSize], AGENT_COORDS_OFFSET, esi
        dec esi ; decrementing cause 1 agent is gone, but he was replaced with last one in agent vector, so need to process him
        sub edi, [AgentRecSize] ; same as esi
        jmp NextAgent
      @@:

      cmp eax, [AgentMinEnergyToClone]
      jb ContinueExecution

      ; cloning agent
      stdcall AgentClone, esi

      ; in case of successful cloning, doing loop one more time (to process new agent too)
      cmp [AgentClonedSuccessfully], 1
      jne @F
        inc ecx 
      @@:
      jmp NextAgent

      ContinueExecution: 
        dec word[edi + AGENT_ENERGY_OFFSET] ; decrementing energy
        movzx ebx, word[edi + AGENT_CURR_INSTR_OFFSET] ; got curr instruction(2B)
        movzx ebx, byte[edi + ebx + AGENT_INSTR_VEC_OFFSET] ; got instruction index (in array of functions to call)
        
        ; checking is it move instruction
        cmp ebx, 4
        jge @F
        ; checking does agent has enough energy to move
        mov eax, [AgentEnergyToMove]
        cmp word[edi + AGENT_ENERGY_OFFSET], ax
        jge @F
        ; if not - skipping move
        jmp skipMove
        @@:


        cmp ebx, 5
        jne @F
        ; checking does agent has enough energy to clone
        mov eax, [AgentEnergyToClone]
        cmp word[edi + AGENT_ENERGY_OFFSET], ax
        jg @F
        jmp skipMove
        @@:
        stdcall dword[AgentTasks + ebx * 4], esi ; calling instruction

        cmp ebx, 5
        jne @F
        cmp [AgentClonedSuccessfully], 0
        je @F
          inc ecx 
        @@:

        skipMove:

        movzx eax, word[edi + AGENT_ENERGY_OFFSET]
        stdcall CalcAgentColor, eax
        stdcall bufUpdateCellColor, [edi + AGENT_COORDS_OFFSET], eax
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

        ; checking that it's time for food to grow
        xor edx, edx
        mov eax, ebp
        div [TimeForFoodToGrow]
        cmp edx, 0
        jne .SkipFoodGrowing
        stdcall GrowFood

        .SkipFoodGrowing:
        inc ebp
      cmp [StopGame], 1
      je GameOver
      
      invoke GetTickCount

      ; getting time passed
      sub eax, [StartTimeMs]

      cmp eax, [FrameDelayMs]
      ; frame too much, don't need extra delays
      jge @F
      mov ecx, [FrameDelayMs]
      sub ecx, eax
      
      invoke Sleep, ecx
      @@:
    
    jmp gameLoop

  GameOver:
  mov [TotalTacts], ebp
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

section '.idata' import data readable writeable
  library kernel32, 'KERNEL32.DLL',\
          gdi32, 'GDI32.DLL', \
          user32, 'USER32.DLL'
          

  import kernel32,\
        Sleep, 'Sleep', \
         GetProcessHeap, 'GetProcessHeap',\
         HeapAlloc, 'HeapAlloc',\
         HeapFree, 'HeapFree',\
         ExitProcess, 'ExitProcess',\
         wsprintf, 'wsprintfA',\
         msvcrt, 'msvcrt.dll',\
         GetModuleHandle, 'GetModuleHandleA', \
         GetTickCount, 'GetTickCount'

  import user32,\
         MessageBox, 'MessageBoxA', \
         GetSystemMetrics, 'GetSystemMetrics', \
         LoadIcon, 'LoadIconA', \
         LoadCursor, 'LoadCursorA', \
         RegisterClass, 'RegisterClassA', \
         CreateWindowEx, 'CreateWindowExA', \
         GetDC, 'GetDC', \
         PeekMessage, 'PeekMessageA', \
         TranslateMessage, 'TranslateMessage', \
         DispatchMessage, 'DispatchMessageA', \
         DefWindowProc, 'DefWindowProcA', \
         PostQuitMessage, 'PostQuitMessage'
  import gdi32,\
         SetDIBitsToDevice, 'SetDIBitsToDevice'
  include 'field.asm'
  include 'assistive.asm'
  include 'gui.asm'
  include 'agents.asm'
