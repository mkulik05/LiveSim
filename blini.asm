format PE GUI 4.0
entry start

include 'win32a.inc'
section '.data' data readable writeable
  ; Game stuff
  TotalTacts dd ?
  HeapHandle dd ?
  TotalAllocSize dd ?
  StopGame dd 0

  
  ; field data
  FieldSize dd 1079
  FieldCellSize dd 1
  FieldAddr dd ?
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
  AgentInitEnergy = 100
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

  ; GUI stuff
  _class TCHAR 'FASMWIN32', 0
  _error TCHAR 'Startup failed.', 0
  wc WNDCLASS 0, WindowProc, 0, 0, NULL, NULL, NULL, COLOR_BTNFACE + 1, NULL, _class
  hDC dd 0
  hwnd dd 0
  bmi BITMAPINFOHEADER
  msg MSG
  ScreenBufAddr dd 0
  ScreenWidth dd 0
  ScreenHeight dd 0
  CellSizePX dd 0
  XFieldOffset dd 0
  YFieldOffset dd 0
  allocFailedMsg db 'allocation failed', 0
  deathMsg db 'EveryoneEveryoneEveryoneEveryoneEveryone died', 0
  deathMsg2 db 'Everyone died', 0
  

section '.text' code readable executable

proc start
  stdcall getFieldSize, [FieldSize] ; got field size
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
  stdcall getFieldSize, [FieldSize]
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


  include 'field.asm'
  include 'assistive.asm'
  include 'agents.asm'
  include 'gui.asm'


proc startGame
  xor ebp, ebp ; tact counter

  gameLoop:
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
        xor byte[ebx + edi], FIELD_AGENT_STATE
        pop edi
        stdcall removeVecItem, [AgentsAddr], AgentsSize, [AgentRecSize], AGENT_COORDS_OFFSET, esi
        dec esi ; decrementing cause 1 agent is gone, but he was replaced with last one in agent vector, so need to process him
        sub edi, [AgentRecSize] ; same as esi
        jmp NextAgent
      @@:

      cmp eax, AgentMinEnergyToClone
      jb ContinueExecution

      ; cloning agent
      stdcall AgentClone, esi
      ;   WTF
      ; inc ecx ; so new agent will go too
      jmp NextAgent

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
      cmp [StopGame], 1
      je GameOver
    jmp gameLoop

  GameOver:
  mov [TotalTacts], ebp
  ret
endp


section '.idata' import data readable writeable
  library kernel32, 'KERNEL32.DLL',\
          gdi32, 'GDI32.DLL', \
          user32, 'USER32.DLL'
          

  import kernel32,\
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
         GetMessage, 'GetMessageA', \
         TranslateMessage, 'TranslateMessage', \
         DispatchMessage, 'DispatchMessageA', \
         DefWindowProc, 'DefWindowProcA', \
         PostQuitMessage, 'PostQuitMessage'
  import gdi32,\
         SetDIBitsToDevice, 'SetDIBitsToDevice'
