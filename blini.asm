format PE GUI 4.0
entry start

section '.data' data readable writeable
  ; filed data
  FieldHeapHandle dd ?
  fieldAddr dd ?
  fieldSize dd 20
  fieldCellSize dd 4
  FieldTotalAllocSize dd ?

  ; agents vec data
  AgentRecSize dd 20
  AgentRecSizeIn = 20
  AgentInitEnergy = 25
  TasksAmount dd 6
  AgentTasks dd 1, 2, 3, 4, 5, 6 ; there will be pointers to instruction functions
  AgentsTotalAllocSize dd ?
  AgentsHeapHandle dd ?
  AgentsCapacity dd ?
  AgentsSize dd ?
  AgentsAddr dd ?
    
  
  allocFailedMsg db 'allocation failed', 0

section '.text' code readable executable
  include 'win32a.inc'


proc start
  stdcall getFieldSize, [fieldSize] ; into eax

  mov [FieldTotalAllocSize], eax
  stdcall allocMem, eax, FieldHeapHandle, fieldAddr

  mov [AgentsSize], 0
  mov eax, [fieldSize]
  mov [AgentsCapacity], eax
  mul [AgentRecSize] ; get agents buffer size
  mov [AgentsTotalAllocSize], eax
  stdcall allocMem, eax, AgentsHeapHandle, AgentsAddr

  stdcall fillField

  stdcall startGame

  ; cleaning up
  invoke HeapFree, [FieldHeapHandle], 0, [FieldTotalAllocSize]
  invoke HeapFree, [AgentsHeapHandle], 0, [AgentsTotalAllocSize]
  invoke ExitProcess, 0
  ret
endp
 
proc startGame
  xor ebp, ebp ; tact counter

  gameLoop:
    mov ecx, [AgentsSize]
    jz GameOver ; all agents died
    xor esi, esi
    AgentsVecLoop:
      mov edi, [AgentsAddr]
      mov eax, esi
      mul dword[AgentRecSize] 
      add edi, eax ; got current agent addr

      ; CHECK ROBOT ENERGY
      movzx eax, word[edi + 8]
      cmp eax, 0
      jg @F
        stdcall removeAgent, esi
      @@:
      mov ebx, dword[edi + 10] ; got curr instruction(2B), total instructions amount(2B)
      shr ebx, 16
      movzx ebp, byte[edi + 13 + ebx] ; got instruction index

      stdcall dword[AgentTasks + ebp * 4] ; calling instruction

      ; switch to next instruction
      inc bx
      cmp bx, word[edi + 12]
      jge ReturnToFirstInstruction
        inc word[edi + 10]
      ReturnToFirstInstruction:
        mov word[edi + 10], 0

      inc esi
      loop AgentsVecLoop

    jmp gameLoop

  GameOver:
  ret
endp

proc removeAgent, ind
    mov edi, [AgentsAddr]
    mov eax, [ind]
    mul dword[AgentRecSize] 
    add edi, eax ; got delete agent addr

    mov esi, [edi + 4] ; coords of agent
    mov dword[fieldAddr + esi * 4], 0 ; clear game field
    
    mov eax, [AgentsSize]
    cmp eax, 1
    jne @F
      jmp finished
    @@:
    inc eax ; cause indexes from zero
    cmp eax, [ind]
    jne @F
      jmp finished
    @@:
      mov esi, [AgentsAddr]
      mov eax, [AgentsSize]
      dec eax ; got index
      mul dword[AgentRecSize] 
      mov esi, eax
      
      mov ecx, [AgentRecSizeIn]
      rep movsb ; write last agent info into whole after removed agent

    finished:
      dec dword[AgentsSize]
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
    
    cmp al, 128
    jl EmptyCell
    cmp al, 200
    jl Food
    jmp Agent
  
    EmptyCell:
      mov dword[fieldAddr + ebx], 0
      jmp @F
    Food:
      ; get also amount of food
      sub al, 128
      shr al, 1
      and eax, $00_00_00_FF
      bts eax, 15

      ; food cell - 10_00_00_1f, 1f - food amount
      mov dword[fieldAddr + ebx], eax
      jmp @F
    Agent:

      ; filling cell in game field
      mov eax, 0
      ; bts eax, 15
      bts eax, 14
      add eax, edi
      ; agent cell - 01_FF_FF_FF, FF_FF_FF - agent index
      mov dword[fieldAddr + ebx], eax

      push ecx
      push esi
      ; filling agents vector
      mov eax, [AgentsCapacity]
      cmp eax, [AgentsSize]
      jg addAgentCell 
      
      stdcall ReallocAgents
      

      addAgentCell: 
      
      mov esi, [AgentsSize]
      mov eax, AgentRecSizeIn
      mul esi
      mov edi, [AgentsAddr]
      add edi, eax
      mov dword[edi], esi ; agent number

      mov eax, [fieldSize] 
      mul [fieldSize]
      sub eax, ecx
      mov dword[edi + 4], eax ; curr coords
      mov word[edi + 8], AgentInitEnergy
      mov word[edi + 10], 0
      stdcall RandGet, 8
      mov word[edi + 12], ax
      push ecx
      mov ecx, eax
      xor ebp, ebp ; curr instruction
      RandInstruction:
        stdcall RandGet, [TasksAmount]
        mov byte[ebp + edi + 13], al
        inc ebp
      loop RandInstruction
      pop ecx

      inc esi
      jmp @F
      
    add ebx, 4
  @@:
    cmp ecx, 0
    jz stopLoop
    jmp loopStart 
  stopLoop:
  ret  
endp

proc ReallocAgents
  mov eax, [AgentsCapacity]
  ; creating new vector with bigger capacity
  shl eax, 1 ; new capacity
  mul dword[AgentRecSize]

  mov ebx, [AgentsTotalAllocSize] ; backing it up 
  mov [AgentsTotalAllocSize], eax

  mov esi, [AgentsAddr] ; backing it up 
  mov edx, [AgentsHeapHandle] ; it too
  stdcall allocMem, eax, AgentsHeapHandle, AgentsAddr
  
  mov ecx, [AgentsSize]
  rep movsd             ; copying prev agents
  pop esi
  pop ecx

  invoke HeapFree, edx, 0, ebx
  ret
endp

; eax - return new rand value up to maxVal
proc RandGet, maxVal
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
proc allocMem, memSize, HeapHandle, bufAddr
  ; getting heap addr
  invoke GetProcessHeap
  mov [HeapHandle], eax
  ; alloc memory for field
  invoke HeapAlloc, [HeapHandle], 0, [memSize]
  mov [bufAddr], eax
  
  
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
