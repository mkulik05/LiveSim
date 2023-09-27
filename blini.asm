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
  stdcall allocMem, eax, FieldTotalAllocSize, FieldHeapHandle, fieldAddr

  stdcall fillField ; eax will store amount of agents

  mov [AgentsSize], eax
  add eax, [fieldSize] ; adding some reserved space for new agents
  mov [AgentsCapacity], eax
  mul [AgentRecSize] ; get agents buffer size
  mov [AgentsTotalAllocSize], eax
  stdcall allocMem, eax, AgentsHeapHandle, AgentsAddr

  mov [FieldTotalAllocSize], eax

  stdcall genAgents, eax

  ; cleaning up
  invoke HeapFree, [FieldHeapHandle], 0, [FieldTotalAllocSize]
  invoke HeapFree, [AgentsHeapHandle], 0, [AgentsTotalAllocSize]
  invoke ExitProcess, 0
  ret
endp
 
proc genAgents, agentsN
  mov ecx, [agentsN]


  ret
endp

 ; eax - return generated amount of agents
proc fillField
  ; get emount of cells to generate
  mov eax, [fieldSize] 
  mul [fieldSize]

  xor ebx, ebx
  xor edi, edi
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
      mov eax, 0
      ; bts eax, 15
      bts eax, 14
      add eax, edi
      ; agent cell - 01_FF_FF_FF, FF_FF_FF - agent index
      mov dword[fieldAddr + ebx], eax
      inc edi
      jmp @F
      
    add ebx, 4
    @@:
    loop loopStart   
    mov eax, edi 
  ret  
endp


; eax - return new rand value up to maxVal
proc RandGet, maxVal
    rdrand ax
    mul [maxVal]
    mov eax, dx
    shl eax, 16
    add eax, dx
    ; in eax - value * NewMax

    xor edx, edx
    mov ecx, 0x00_00_FF_FF 
    div ecx
    ret 
endp

; Allocate required amount of memory (memSize) for field. Save it's size in "TotalAllocSize". Stores heapHandle in HeapHandle
proc allocMem, memSize, TotalAllocSize, HeapHandle, bufAddr
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
