; Settings
  Width = 1600
  Height = 700
  R = 0
  G = 0
  B = 0

; Code
format PE GUI 4.0
entry start

include 'win32w.inc'

section '.data' data readable writeable
  _class TCHAR 'FASMWIN32', 0
  _title TCHAR 'GDI32 Test', 0
  _error TCHAR 'Startup failed.', 0

  wc WNDCLASS 0, WindowProc, 0, 0, NULL, NULL, NULL, COLOR_BTNFACE + 1, NULL, _class

  msg MSG
  hDC dd 0
  hwnd dd 0
  bmi BITMAPINFOHEADER

  ; Define the variables for heap memory allocation
  heapHandle dd 0
  heapMemory dd 0
  heapSize dd Width * Height * 4 ; 4 bytes per pixel (32-bit)

section '.text' code readable executable

proc start
  invoke GetModuleHandle, 0
  mov [wc.hInstance], eax
  invoke LoadIcon, 0, IDI_APPLICATION
  mov [wc.hIcon], eax
  invoke LoadCursor, 0, IDC_ARROW
  mov [wc.hCursor], eax
  invoke RegisterClass, wc
  test eax, eax
  jz error

  invoke CreateWindowEx, 0, _class, _title, WS_VISIBLE + WS_DLGFRAME + WS_SYSMENU, 128, 128, 1600, 700, NULL, NULL, [wc.hInstance], NULL
  mov [hwnd], eax
  invoke GetDC, [hwnd]
  mov [hDC], eax
  mov [bmi.biSize], sizeof.BITMAPINFOHEADER
  mov [bmi.biWidth], Width
  mov [bmi.biHeight], Height
  mov [bmi.biPlanes], 1
  mov [bmi.biBitCount], 32
  mov [bmi.biCompression], BI_RGB

  mov [heapHandle], 0

  invoke GetProcessHeap
  mov [heapHandle], eax

  invoke HeapAlloc, [heapHandle], HEAP_ZERO_MEMORY, [heapSize]
  test eax, eax
  jz error

  mov [heapMemory], eax

  mov edi, [heapMemory]
  mov ecx, Width * Height
  mov eax, (B shl 16) + (G shl 8) + R
  rep stosd

  stdcall DrawRect, [heapMemory], 200, 200, 300, 800, 0x00F09F00
  stdcall DrawRect, [heapMemory], 200, 200, 200, 700, 0x00FF1911
  stdcall DrawRect, [heapMemory], 150, 150, 200, 500, 0x00000000


  msg_loop:
    invoke GetMessage, msg, NULL, 0, 0
    cmp eax, 1
    jb end_loop
    jne msg_loop
    
    invoke TranslateMessage, msg
    invoke DispatchMessage, msg
    invoke SetDIBitsToDevice, [hDC], 0, 0, Width, Height, 0, 0, 0, Height, [heapMemory], bmi, 0
    jmp msg_loop

  error:
    invoke MessageBox, NULL, _error, NULL, MB_ICONERROR + MB_OK

  end_loop:
    invoke HeapFree, [heapHandle], 0, [heapMemory]

    invoke ExitProcess, [msg.wParam]
  ret 
  endp

proc DrawRect uses eax ebx edx ecx edi, buffer, x, y, height, width, color
  mov ecx, [height]
  mov eax, Width * 4
  mul [y]
  mov edi, [buffer]
  add edi, eax
  mov eax, [x]
  shl eax, 2
  add edi, eax
  
  mov edx, eax ; backed up
  mov eax, [color]
  rectangleLoop:
      push ecx

          mov ecx, [width]

          
          rep stosd
          mov ebx, [width]
          shl ebx, 2
          sub edi, ebx
          add edi, Width * 4

      pop ecx
  loop rectangleLoop

  ret 
endp


proc WindowProc uses ebx esi edi, hwnd, wmsg, wparam, lparam
  cmp [wmsg], WM_DESTROY
  je .wmdestroy
  .defwndproc:
  invoke DefWindowProc, [hwnd], [wmsg], [wparam], [lparam]
  jmp .finish
  .wmdestroy:
  invoke PostQuitMessage, 0
  xor eax, eax
  .finish:
  ret
endp

section '.idata' import data readable writeable
  library kernel32, 'KERNEL32.DLL', \
    gdi32, 'GDI32.DLL', \
    user32, 'USER32.DLL'

  include 'api\kernel32.inc'
  include 'api\gdi32.inc'
  include 'api\user32.inc'
