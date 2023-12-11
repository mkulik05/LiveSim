format PE GUI 4.0
entry EntryPoint

include 'win32a.inc'
section '.data' data readable writeable
  ; Game stuff
  FrameDelayMs dd 0
  MaxWaitTime = 32 ; in ms max time per one sleep, if need more time - splitted into sev sleep (to make app responsible)
  PauseWaitTime = 10 ; ms to pause program for, while waiting for resume

  TotalTacts dd 0
  HeapHandle dd ?
  TotalAllocSize dd ?
  StartTimeMs dd ?
  StopGame dd 0
  PauseGame dd 1
  PutOnPauseNextTact dd 0
  SettingsToSave dd AgentInitEnergy, AgentEnergyToMove, AgentEnergyToClone, AgentMinEnergyToClone, AgentMutationOdds, FoodMaxValue, TimeForFoodToGrow, FoodGrowMaxValue, FoodMaxInitAmount
  AMOUNT_OF_SETTINGS = 9

  ; field data
  FieldSize dd 128
  FIELD_CELL_SIZE = 4
  FieldAddr dd ?
  FIELD_AGENT_STATE = 0100_0000_0000_0000_0000_0000_0000_0000b
  FIELD_FOOD_STATE = 1000_0000_0000_0000_0000_0000_0000_0000b
  FIELD_SAFE_MASK = 0011_1111_1111_1111_1111_1111_1111_1111b

  ; agents vec data
  AGENT_MAX_INSTRUCTIONS_N = 10 ; RFF
  AgentRecSize dd 10 + AGENT_MAX_INSTRUCTIONS_N
  AGENT_COORDS_OFFSET = 0 ; 4B
  AGENT_ENERGY_OFFSET = 4 ; 2B
  AGENT_CURR_INSTR_OFFSET = 6 ; 2B
  AGENT_INSTR_NUM_OFFSET = 8  ; 2B
  AGENT_INSTR_VEC_OFFSET = 10 ; B[]
  AgentInitEnergy dd 200 ; read from file (RFF)
  AgentTaskMaxInd dd 5
  AgentTasks dd AgentMoveTop, AgentMoveRight, AgentMoveDown, AgentMoveLeft, AgentSleep, AgentClone
  AgentsCapacity dd ?
  AgentsSize dd 0
  AgentsAddr dd ?
  AgentEnergyToMove dd 20 ; RFF
  AgentEnergyToClone dd 150 ; RFF   ; should be less then AgentMinEnergyToClone
  AgentMinEnergyToClone dd 252 ; RFF
  AgentClonedSuccessfully dd 0
  AgentMutationOdds dd 0 ; RFF in percents
    
  ; food info
  FoodMaxValue dd 250 ; RFF
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
  NextFoodSpawnN dd ?
  NextFoodSpawnT dd ?
  NextFoodSpawnTMax dd 40
  NextFoodSpawnNMax dd 512 * 50
  SpawnedFoodMaxAmount dd 50

  ; GUI stuff
  CursorType dd IDC_CROSS
  isCursorShown dd 1
  EMPTY_COLOR = 0x00000000
  ScreenBufAddr dd 0
  CellSizePX dd 0
  ScreenWidth dd 0
  ScreenHeight dd 0
  XFieldOffset dd 0
  YFieldOffset dd 0

  FieldSizePx dd 0
  FieldZoneHeight dd 0
  FieldZoneWidth dd 0
  FieldXInOffset dd 0
  FieldYInOffset dd 0

; ------ DRAWING

  isDrawingActive dd 0
  isDrawingAgent dd 0
  isDrawingClear dd 0

; ------ CONSOLE

  ; Process commands
  ; ame - agent move energy
  ; ace - agent clone energy
  ; amo - agent mutation odds
  ; fgl - food grow limit
  ; fgt - food grow time
  ; tft - time for tact (in ms)
  ; mce - min clone energy
  ; fma - food max amount
  ; fia - food max init amount
  ; fms - food max spawn amount
  ConsoleEditCommands db 'ame', 'ace', 'amo', 'fgl', 'fgt', 'tft', 'mce', 'fma', 'fia', 'fms'
  COMMAND_EDIT_LEN = 3
  CommandsEditLabel dd AgentEnergyToMove, AgentEnergyToClone, AgentMutationOdds, FoodGrowMaxValue, TimeForFoodToGrow, FrameDelayMs, AgentMinEnergyToClone, FoodMaxValue, FoodMaxInitAmount, SpawnedFoodMaxAmount
  COMMANDS_EDIT_N = 10

  ; unlike ConsoleEditCommands - action commands are not just editing corresponding label
  ; each calls corresponding function with number param
  ; cfs - change field
  ; fsa - foos spawn amount
  ; dra - draw agent
  ; drf - draw food
  ; drs - draw stop 
  ConsoleActionCommands db 'cfs', 'rst', 'fsa', 'dra', 'drf', 'drs', 'drc'
  ConsoleActionNeedParam db 1, 0, 1, 0, 0, 0, 0
  COMMAND_ACTION_LEN = 3
  CommandsActionLabel dd CommandChangeFieldSize, CommandReset, CommandChangeFoodSpawnAmount, CommandAgentDraw, CommandFoodDraw, CommandStopDraw, CommandClearDraw
  COMMANDS_ACTION_N = 7

  ConsoleBufSavesN dd 10
  ConsoleBufSaves dd ConsoleBufSave1, ConsoleBufSave2, ConsoleBufSave3, ConsoleBufSave4, ConsoleBufSave5, ConsoleBufSave6, ConsoleBufSave7, ConsoleBufSave8, ConsoleBufSave9, ConsoleBufSave10
  ConsoleBufCurrSave dd -1
  ConsoleBufSave1 db (ConsoleBufSize + 1) dup ?
  ConsoleBufSave2 db (ConsoleBufSize + 1) dup ?
  ConsoleBufSave3 db (ConsoleBufSize + 1) dup ?
  ConsoleBufSave4 db (ConsoleBufSize + 1) dup ?
  ConsoleBufSave5 db (ConsoleBufSize + 1) dup ?
  ConsoleBufSave6 db (ConsoleBufSize + 1) dup ?
  ConsoleBufSave7 db (ConsoleBufSize + 1) dup ?
  ConsoleBufSave8 db (ConsoleBufSize + 1) dup ?
  ConsoleBufSave9 db (ConsoleBufSize + 1) dup ?
  ConsoleBufSave10 db (ConsoleBufSize + 1) dup ?


  ; if 1 - input is captured by console, otherwise - by main window
  ; toggled by slash 'tab'
  ConsoleInputMode dd 0
  ConsoleBufSize = 10
  ConsoleInpBuf db (ConsoleBufSize + 1) dup ?
  ConsoleErrorMsg db 'Error', 0
  ConsoleCharsN dd 0
  ConsoleActiveText db '|', 0

  isGUIInited dd 0
  maxTextWidth dd 0
  numStr TCHAR 0, 0, 0, 0, 0, 0, 0, 0, 0
  tactNStr TCHAR 'Tact ', 0
  tactNStrLen = 5
  agentsNStr TCHAR 'Agents      ', 0
  agentsNStrLen = 12
  foodNStr TCHAR 'Food ', 0
  foodNStrLen = 5
  _class TCHAR 'FASMWIN32', 0
  _error TCHAR 'Startup failed.', 0
  wc WNDCLASS 0, WindowProc, 0, 0, NULL, NULL, NULL, COLOR_BTNFACE + 1, NULL, _class
  hBufDC dd 0
  hMainDc dd 0
  hwnd dd 0
  bmi BITMAPINFOHEADER
  msg MSG
  TEXT_FONT_SIZE = 50
  TEXT_CHAT_FONT_SIZE = 40
  TEXT_MARGIN_LEFT = 20
  TEXT_MARGIN_TOP = 20
  GAME_BKG_COLOR = 00FFFFFFh
  bkgBrush dd ?
  lf LOGFONT
  savedMsg db 'saved successfullyu', 0
  fname1 TCHAR 'C:\Users\mk\Documents\blini\ws\coolfile1', 0
  fname2 TCHAR 'C:\Users\mk\Documents\blini\ws\coolfile2', 0
  allocFailedMsg db 'allocation failed', 0
  deathMsg2 db 'EveryoneEveryoneEveryoneEveryoneEveryone died', 0
  deathMsg db 'Each agent died', 0
  genFieldMsg db 'Generating field...', 0
  

section '.text' code readable executable

; based on fieldSize calc TotalAllocSize, allocMem, calculate agent and food vectors addrs, screen buf addr
proc Initialisation
  mov eax, FIELD_CELL_SIZE
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

  
  cmp [isGUIInited], 1
  je @F
  push eax
  stdcall GUIBasicInit
  mov [isGUIInited], 1
  pop eax
  @@:

  ; getting amount of bytes
  mov edx, [AgentRecSize]
  add edx, [FoodRecSize]
  mul edx ; got size for agents, food
  add [TotalAllocSize], eax ; total size

  ; getting amount of bytes for screen buffer
  mov eax, [FieldZoneWidth]
  mul [FieldZoneHeight]
  shl eax, 2
  add [TotalAllocSize], eax

  stdcall allocMem, [TotalAllocSize], HeapHandle, FieldAddr

  ; calculating AgentsAddr
  mov ebx, [FieldAddr]
  mov eax, FIELD_CELL_SIZE
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
  ret
endp

proc EntryPoint
  stdcall Initialisation
  stdcall calcMaxConsoleLines
  stdcall ShowGeneratingFieldMsg
  stdcall fillField

  stdcall RandInt, [NextFoodSpawnTMax]
  inc eax
  mov [NextFoodSpawnT], eax

  stdcall RandInt, [NextFoodSpawnNMax]
  inc eax
  mov [NextFoodSpawnN], eax

  stdcall start
  ret 
endp

proc start

  stdcall drawBkg
  stdcall calcCellSize ; will put result into CellSizePX constant
  
  mov eax, [FieldSize]
  mul [CellSizePX]
  mov [FieldSizePx], eax
  
  stdcall calcFieldOffsets ; inits YFieldOffset and XFieldOffset
  stdcall drawField
  stdcall calcLeftTextOffset
  stdcall startGame


  stdcall GameOverProc

  ret
endp

proc ShowGeneratingFieldMsg
  local rect RECT 
  mov [rect.left], 0
  mov eax, [ScreenWidth]
  mov [rect.right], eax
  mov eax, [FieldZoneHeight]
  mov [rect.bottom], eax
  shr eax, 1
  mov [rect.top], eax
  sub [rect.top], TEXT_FONT_SIZE
  add [rect.bottom], TEXT_FONT_SIZE

  push [lf.lfHeight]
  mov [lf.lfHeight], TEXT_FONT_SIZE * 2
  invoke CreateFontIndirect, lf
  invoke SelectObject, [hBufDC], eax
  lea eax, [rect]
  invoke DrawText, [hBufDC], genFieldMsg, -1, eax, DT_CENTER
  pop [lf.lfHeight]
  invoke CreateFontIndirect, lf
  invoke SelectObject, [hBufDC], eax
  invoke BitBlt, [hMainDc], 0, 0, [ScreenWidth], [ScreenHeight], [hBufDC], 0, 0, SRCCOPY
  ret 
endp

proc GameOverProc 
  local rect RECT 
  mov [rect.left], 0
  mov eax, [ScreenWidth]
  mov [rect.right], eax
  mov eax, [FieldZoneHeight]
  mov [rect.bottom], eax
  shr eax, 1
  mov [rect.top], eax
  sub [rect.top], TEXT_FONT_SIZE
  add [rect.bottom], TEXT_FONT_SIZE

  push [lf.lfHeight]
  mov [lf.lfHeight], TEXT_FONT_SIZE * 2
  invoke CreateFontIndirect, lf
  invoke SelectObject, [hBufDC], eax
  lea eax, [rect]
  invoke DrawText, [hBufDC], deathMsg, -1, eax, DT_CENTER
  pop [lf.lfHeight]
  invoke CreateFontIndirect, lf
  invoke SelectObject, [hBufDC], eax
  invoke BitBlt, [hMainDc], 0, 0, [ScreenWidth], [ScreenHeight], [hBufDC], 0, 0, SRCCOPY
  ; game can be reseted using console
  mov [PauseGame], 1
  .Paused:
    invoke Sleep, PauseWaitTime 
    stdcall ProcessWindowMsgs
  jmp .Paused
  ret 
endp

proc startGame
  
  xor ebp, ebp ; tact counter

  gameLoop:
    stdcall PrintStats  
    invoke SetDIBitsToDevice, [hBufDC], [FieldXInOffset], [FieldYInOffset], [FieldZoneWidth], [FieldZoneHeight], 0, 0, 0, [FieldZoneHeight], [ScreenBufAddr], bmi, 0
    invoke BitBlt, [hMainDc], 0, 0, [ScreenWidth], [ScreenHeight], [hBufDC], 0, 0, SRCCOPY
    stdcall ProcessWindowMsgs

    cmp [PutOnPauseNextTact], 1
    jne .IsPausedCheck
    mov [PauseGame], 1
    mov [PutOnPauseNextTact], 0

    .IsPausedCheck:

    cmp [PauseGame], 1
    jne continueGameLoop

    @@:

    .Paused:
      cmp [PauseGame], 0
      je continueGameLoop
      invoke Sleep, PauseWaitTime 
      stdcall ProcessWindowMsgs
    jmp .Paused

    continueGameLoop:
    invoke GetTickCount
    mov [StartTimeMs], eax
 
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
        xor dword[ebx + edi * FIELD_CELL_SIZE], FIELD_AGENT_STATE
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
      dec word[edi + AGENT_ENERGY_OFFSET]
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
        mov [TotalTacts], ebp
      cmp [StopGame], 1
      je GameOver
      
      cmp [NextFoodSpawnT], ebp
      jne @F
      stdcall GenFood
        stdcall RandInt, [NextFoodSpawnTMax]
        inc eax
        add [NextFoodSpawnT], eax
        
        stdcall RandInt, [NextFoodSpawnNMax]
        mov [NextFoodSpawnN], eax
      @@:

      invoke GetTickCount

      ; getting time passed
      sub eax, [StartTimeMs]

      cmp eax, [FrameDelayMs]
      ; frame too much, don't need extra delays
      jge @F
      mov ecx, [FrameDelayMs]
      sub ecx, eax
      cmp ecx, MaxWaitTime
      jge .splitWait
      invoke Sleep, ecx
      jmp @F
      .splitWait:
      shr ecx, 5
      cmp ecx, 0
      jbe @F
      mov ebx, MaxWaitTime
      .waiter:
        push ecx 
        stdcall ProcessWindowMsgs
        invoke Sleep, ebx
        pop ecx
      loop .waiter

      @@:
    jmp gameLoop

  GameOver:
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
         GetTickCount, 'GetTickCount', \
         CreateFile, 'CreateFileA', \
         WriteFile, 'WriteFile', \
         ReadFile, 'ReadFile', \
         CloseHandle, 'CloseHandle'

  import user32,\
         GetClientRect, 'GetClientRect', \
         DrawText, 'DrawTextA', \
         MessageBox, 'MessageBoxA', \
         GetSystemMetrics, 'GetSystemMetrics', \
         LoadIcon, 'LoadIconA', \
         LoadCursor, 'LoadCursorA', \
         SetCursor, 'SetCursor', \
         ShowCursor, 'ShowCursor', \
         RegisterClass, 'RegisterClassA', \
         CreateWindowEx, 'CreateWindowExA', \
         GetDC, 'GetDC', \
         PeekMessage, 'PeekMessageA', \
         TranslateMessage, 'TranslateMessage', \
         DispatchMessage, 'DispatchMessageA', \
         DefWindowProc, 'DefWindowProcA', \
         PostQuitMessage, 'PostQuitMessage', \
         FillRect, 'FillRect'
  import gdi32,\
         CreateSolidBrush, 'CreateSolidBrush',\
         SelectObject, 'SelectObject', \
         CreateFontIndirect, 'CreateFontIndirectA', \
         SetDIBitsToDevice, 'SetDIBitsToDevice', \
         GetTextExtentPoint32, 'GetTextExtentPoint32A', \
         BitBlt, 'BitBlt', \
         CreateCompatibleDC, 'CreateCompatibleDC', \
         CreateCompatibleBitmap, 'CreateCompatibleBitmap'
  include 'field.asm'
  include 'agents.asm'
  include 'food.asm'
  include 'assistive.asm'
  include 'gui.asm'
  include 'commands.asm'
  include 'files.asm'