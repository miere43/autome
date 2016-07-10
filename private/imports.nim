import winlean, dynlib

type
  Point* {.pure, final.} = tuple
    x: int32
    y: int32
  RECT* {.pure, final.} = tuple
    left, top, right, bottom: int32
  MOUSEINPUT* {.pure, final.} = object
    kind*: DWORD
    dx*: LONG
    dy*: LONG
    mouseData*: DWORD
    dwFlags*: DWORD
    time*: DWORD
    dwExtraInfo*: pointer
  KEYBDINPUT* {.pure, final.} = object
    kind*: DWORD
    wVk*: int16
    wScan*: int16
    dwFlags*: DWORD
    time*: DWORD
    dwExtraInfo*: pointer
  WINDOWPLACEMENT* {.pure, final.} = object
    length*: uint32
    flags*: uint32
    showCmd*: uint32
    ptMinPosition*: Point
    ptMaxPosition*: Point
    rcNormalPosition*: RECT

const
  inputStructSize* = 28
  INPUT_MOUSE* = 0
  INPUT_KEYBOARD* = 1
  INPUT_HARDWARE* = 2
  MOUSEEVENTF_ABSOLUTE* = 0x8000
  MOUSEEVENTF_LEFTDOWN* = 0x0002
  MOUSEEVENTF_LEFTUP* = 0x0004
  MOUSEEVENTF_RIGHTDOWN* = 0x0008
  MOUSEEVENTF_RIGHTUP* = 0x0010
  MOUSEEVENTF_MIDDLEDOWN* = 0x0020
  MOUSEEVENTF_MIDDLEUP* = 0x0040
  VK_DELETE* = 0x2E.int16
  VK_BACK* = 0x08.int16
  KEYEVENTF_KEYUP* = 0x0002
  KEYEVENTF_UNICODE* = 0x0004
  SWP_NOSIZE* = 0x0001.uint32
  SWP_NOMOVE* = 0x0002.uint32
  SWP_NOACTIVATE* = 0x0010.uint32
  #SW_SHOWNORMAL* = 1.uint32
  SW_RESTORE* = 9.uint32

when useWinUnicode:
  type WinString* = WideCString
else:
  type WinString* = cstring

proc newWinString*(str: string): WinString =
  if str == nil:
    result = nil
  else:
    when useWinUnicode:
      result = newWideCString(str)
    else:
      result = cstring(str)

## Retrieves the position of the mouse cursor, in screen coordinates.
proc getCursorPos*(lpPoint: ptr POINT): WINBOOL 
  {.stdcall, dynlib: "user32", importc: "GetCursorPos".}

proc setCursorPos*(x: int, y: int): WINBOOL
  {.stdcall, dynlib: "user32", importc: "SetCursorPos".}

proc sleep*(dwMilliseconds: DWORD): void
  {.stdcall, dynlib: "kernel32", importc: "Sleep".}

proc sendInput*(nInputs: uint, pInputs: pointer, cbSize: int): uint
  {.stdcall, dynlib: "user32", importc: "SendInput".}

proc getMessageExtraInfo*(): pointer
  {.stdcall, dynlib: "user32", importc: "GetMessageExtraInfo".}

# https://msdn.microsoft.com/en-us/library/windows/desktop/ms633539(v=vs.85).aspx
proc setForegroundWindow*(hWnd: Handle): WINBOOL
  {.stdcall, dynlib: "user32", importc: "SetForegroundWindow".}

proc mapVirtualKey*(uCode, uMapType: uint32): uint32
  {.stdcall, dynlib: "user32", importc: "MapVirtualKeyA".}

proc wEnumWindows*(
    lpEnumFunc: proc(hwnd: Handle, lParam: pointer): WINBOOL {.stdcall.},
    lParam: pointer): WINBOOL
  {.stdcall, dynlib: "user32", importc: "EnumWindows".}

proc getWindowThreadProcessId*(hWnd: Handle, lpdwProcessId: ptr DWORD): DWORD 
  {.stdcall, dynlib: "user32", importc: "GetWindowThreadProcessId".}

proc getCurrentThreadId*(): DWORD
  {.stdcall, dynlib: "kernel32", importc: "GetCurrentThreadId".}

proc attachThreadInput*(idAttach, idAttachTo: DWORD, fAttach: WINBOOL): WINBOOL
  {.stdcall, dynlib: "user32", importc: "AttachThreadInput".}

proc setFocus*(hWnd: Handle): Handle 
  {.stdcall, dynlib: "user32", importc: "SetFocus".}

proc getWindowText*(hWnd: Handle, lpString: pointer, nMaxCount: int): int
  {.stdcall, dynlib: "user32", importc: "GetWindowTextA".}

proc getWindowRect*(hWnd: Handle, lpRect: ptr RECT): WINBOOL
  {.stdcall, dynlib: "user32", importc: "GetWindowRect".}

proc getClientRect*(hWnd: Handle, lpRect: ptr RECT): WINBOOL
  {.stdcall, dynlib: "user32", importc: "GetClientRect".}

proc isIconic*(hWnd: Handle): WINBOOL
  {.stdcall, dynlib: "user32", importc: "IsIconic".}
  ## Determines whether the specified window is minimized (iconic).

proc showWindow*(hWnd: Handle, nCmdShow: int): WINBOOL
  {.stdcall, dynlib: "user32", importc: "ShowWindow".}

proc isZoomed*(hWnd: Handle): WINBOOL
  {.stdcall, dynlib: "user32", importc: "IsZoomed".}
  ## not zoomed => 0, zoomed => != 0

proc setWindowPos*(hWnd, hWndInsertAfter: Handle, x, y, cx, cy: int,
    flags: uint32): WINBOOL
  {.stdcall, dynlib: "user32", importc: "SetWindowPos".}

proc wSetForegroundWindow*(hWnd: Handle): WINBOOL
  {.stdcall, dynlib: "user32", importc: "SetForegroundWindow".}

proc getWindowPlacement*(hWnd: Handle, lpwndpl: ptr WINDOWPLACEMENT): WINBOOL
  {.stdcall, dynlib: "user32", importc: "GetWindowPlacement".}

proc setWindowPlacement*(hWnd: Handle, lpwndpl: ptr WINDOWPLACEMENT): WINBOOL
  {.stdcall, dynlib: "user32", importc: "SetWindowPlacement".}

proc windowFromPoint*(Point: Point): Handle
  {.stdcall, dynlib: "user32", importc: "WindowFromPoint".}

when useWinUnicode:
  proc findWindow*(lpClassName, lpWindowName: WinString): Handle
    {.stdcall, dynlib: "user32", importc: "FindWindowW".}
  #proc WideCharToMultiByte()
else:
  proc findWindow*(lpClassName, lpWindowName: WinString): Handle
    {.stdcall, dynlib: "user32", importc: "FindWindowA".}
  #proc mapVirtualKey*(uCode, uMapType: uint32): uint32
  #  {.stdcall, dynlib: "user32", importc: "MapVirtualKeyW".}