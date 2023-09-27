format PE GUI 4.0
entry start

section '.data' data readable writeable
  HeapHandle dd 0
  fieldAddr dd 0
  fieldSize dd 20
  fieldCellSize dd 4
  TotalAllocSize dd ?
  buffer dd 20 dup(?)
  ;wMax    dd 10
  ;wMin    dd 0
  ;RandwPrevNumber      dd      ?
  ;randomMaxLen dd 20
  
  allocFailedMsg db 'allocation failed', 0

section '.text' code readable executable
  include 'win32a.inc'


proc start
  ;stdcall RandInit
  stdcall getFieldSize, [fieldSize]
  stdcall allocField, eax
  stdcall fillField
  invoke HeapFree, [HeapHandle], 0, [TotalAllocSize]
  invoke ExitProcess, 0
  ret
endp
        

proc RandInit 
    ; setting seed
    invoke GetTickCount
    mov        [RandwPrevNumber], eax
  ret
endp
      
 
proc fillField
  mov eax, [fieldSize] 
  mul [fieldSize]
  xor ebx, ebx
  xor edi, edi
  mov ecx, eax
  ;mov ebx, [randomMaxLen]
  loopStart:
    rdrand ax
    
    cmp ax, 128
    jl EmptyCell
    cmp ax, 200
    jl Food
    jmp Agent
  
    EmptyCell:
      mov dword[fieldAddr + ebx], 0
      jmp @F
    Food:
      sub ax, 128
      shr ax, 2
      and ax, $00_00_00_FF
      bts eax, 15
      mov dword[fieldAddr + ebx], eax
      jmp @F
    Agent:
      mov eax, 0
      bts eax, 15
      bts eax, 14
      add eax, edi
      mov dword[fieldAddr + ebx], eax
      jmp @F
      
    add ebx, 4
      
    ;dec ebx
    ;cmp ebx, 0
    ;ja @F
    ;   stdcall RandInit
    ;   mov ebx, [randomMaxLen]
    @@:
    loop loopStart    
  ret  
endp

proc RandGet
    mov        eax, [Random.wPrevNumber]
    rol        eax, 7
    adc        eax, 23
    mov        [Random.wPrevNumber], eax
    inc     [Random.wPrevNumber]
    mov        ecx, [wMax]
    sub        ecx, [wMin]
    inc        ecx
    xor        edx, edx
    div        ecx
    add        edx, [wMin]
    xchg       eax, edx  
  ret 
endp

proc allocField, memSize
  ; getting heap addr
  invoke GetProcessHeap
  mov [HeapHandle], eax
  
  ; saving allocated memory size
  mov eax, [memSize]
  mov [TotalAllocSize], eax
  ; alloc memory for field
  invoke HeapAlloc, [HeapHandle], 0, [memSize]
  mov [fieldAddr], eax
  
  
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
