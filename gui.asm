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

  jmp @F
  error:
    invoke MessageBox, NULL, _error, NULL, MB_ICONERROR + MB_OK

  @@:
  ret 
endp

proc ProcessWindowMsgs
  invoke GetMessage, msg, NULL, 0, 0
  cmp eax, 1
  jb .end_loop
  je @F
    ret
  
  @@:
  invoke TranslateMessage, msg
  invoke DispatchMessage, msg
  invoke SetDIBitsToDevice, [hDC], 0, 0, [ScreenWidth], [ScreenHeight], 0, 0, 0, [ScreenHeight], [ScreenBufAddr], bmi, 0

  jmp @F
  .end_loop:
    mov [StopGame], 1
  
  @@:
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


proc calcCellSize
  ; assuming that height is less then width
  mov eax, [ScreenHeight] 
  div [FieldSize]

  cmp eax, 0
  je .LessThen1PX
  mov [CellSizePX], eax
  jmp .Finished
  .LessThen1PX:
    mov [CellSizePX], 0xFF
    ; NEEDS TO BE DONE
  .Finished:

  ret
endp

proc calcFieldOffsets
  mov ebx, [ScreenHeight]
  
  ; getting size of field in pixels
  mov eax, [FieldSize]
  mul [CellSizePX]

  ; calculating left space on screen in Y axis
  sub ebx, eax
  shr ebx, 1
  mov [YFieldOffset], ebx

  ; same for X-axis
  mov ebx, [ScreenWidth]
  sub ebx, eax
  shr ebx, 1
  mov [XFieldOffset], ebx

  ret
endp

proc drawField
  mov eax, [FieldSize]
  mul [FieldSize]
  mov ecx, eax 
  mov edi, [FieldAddr]
  mov ebx, [XFieldOffset] ; X coords offset
  mov ebp, [YFieldOffset] ; Y coords offset 
  .GoThoughFieldCells:
    mov eax, 0 ; storing there color
    test byte[edi], FIELD_AGENT_STATE
    jz @F
    mov eax, 0x00FF0000
    jmp .stopColorSelection
    @@:
    test byte[edi], FIELD_FOOD_STATE
    jz .stopColorSelection
    mov eax, 0x000000FF
    .stopColorSelection:
    stdcall DrawRect, [ScreenBufAddr], ebx, ebp, [CellSizePX], [CellSizePX], eax

    add ebx, [CellSizePX]
    mov eax, [ScreenWidth]
    sub eax, [XFieldOffset]
    dec eax
    cmp ebx, eax
    jb @F

    .NextLine:
      add ebp, [CellSizePX]
      mov ebx, [XFieldOffset]
    @@:
    inc edi
    loop .GoThoughFieldCells

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