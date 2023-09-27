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

  ; cleaning up
  invoke HeapFree, [FieldHeapHandle], 0, [FieldTotalAllocSize]
  invoke HeapFree, [AgentsHeapHandle], 0, [AgentsTotalAllocSize]
  invoke ExitProcess, 0
  ret
endp
 
 ; eax - return generated amount of agents
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
      mov word[edi + 8], 0
      stdcall RandGet, 8
      mov word[edi + 10], ax
      push ecx
      mov ecx, eax
      xor ebp, ebp ; curr instruction
      RandInstruction:
        stdcall RandGet, [TasksAmount]
        mov byte[ebp + edi + 11], al
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
