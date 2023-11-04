proc GUIBasicInit

  ; getting screen X size and Y
  invoke GetSystemMetrics, SM_CXSCREEN
  mov [ScreenWidth], eax

  invoke GetSystemMetrics, SM_CYSCREEN
  mov [ScreenHeight], eax

  invoke GetModuleHandle, 0
  mov [wc.hInstance], eax
  invoke LoadIcon, 0, IDI_APPLICATION
  mov [wc.hIcon], eax
  invoke LoadCursor, 0, IDC_ARROW
  mov [wc.hCursor], eax
  invoke RegisterClass, wc
  test eax, eax
  jz error

  invoke CreateWindowEx, 0, _class, 0, WS_VISIBLE + WS_POPUP, 0, 0, [ScreenWidth], [ScreenHeight], NULL, NULL, [wc.hInstance], NULL
  
  mov [hwnd], eax
  invoke GetDC, [hwnd]
  mov [hDC], eax
  mov [bmi.biSize], sizeof.BITMAPINFOHEADER
  mov eax, [ScreenWidth]
  mov [bmi.biWidth], eax
  mov eax, [ScreenHeight]
  mov [bmi.biHeight], eax
  mov [bmi.biPlanes], 1
  mov [bmi.biBitCount], 32
  mov [bmi.biCompression], BI_RGB

  ; stdcall DrawRect, [heapMemory], 200, 200, 300, 800, 0x00F09F00
  ; stdcall DrawRect, [heapMemory], 200, 200, 200, 700, 0x00FF1911
  ; stdcall DrawRect, [heapMemory], 150, 150, 200, 500, 0x00000000

  ret 
  endp

proc ProcessWindowMsgs
  invoke GetMessage, msg, NULL, 0, 0
  cmp eax, 1
  jb end_loop
  ret
  
  invoke TranslateMessage, msg
  invoke DispatchMessage, msg
  invoke SetDIBitsToDevice, [hDC], 0, 0, [ScreenWidth], [ScreenHeight], 0, 0, 0, [ScreenHeight], [ScreenBufAddr], bmi, 0

  error:
    invoke MessageBox, NULL, _error, NULL, MB_ICONERROR + MB_OK

  end_loop:
    mov [StopGame], 1
  ret 
  endp

proc drawBkg
  mov edi, [ScreenBufAddr]
  mov eax, [ScreenWidth]
  mul [ScreenHeight]
  mov ecx, eax
  mov eax, 0xFFFFFFFF
  rep stosd
  ret
endp

proc DrawRect uses eax ebx edx ecx edi, buffer, x, y, height, width, color
  mov ecx, [height]
  mov eax, [ScreenWidth]
  shl eax, 2
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
          mov ebx, [ScreenWidth]
          shl ebx, 2
          add edi, ebx

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