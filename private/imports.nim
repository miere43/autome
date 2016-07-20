import winlean, dynlib

type
  RECT {.pure, final.} = tuple 
    left, top, right, bottom: int32
  MOUSEINPUT {.pure, final.} = object
    kind: DWORD
    dx: LONG
    dy: LONG
    mouseData: DWORD
    dwFlags: DWORD
    time: DWORD
    dwExtraInfo: pointer
  KEYBDINPUT {.pure, final.} = object
    kind: DWORD
    wVk: int16
    wScan: int16
    dwFlags: DWORD
    time: DWORD
    dwExtraInfo: pointer
  WINDOWPLACEMENT {.pure, final.} = object
    length: uint32
    flags: uint32
    showCmd: uint32
    ptMinPosition: Point
    ptMaxPosition: Point
    rcNormalPosition: RECT
  MSG {.pure, final.} = object
    hwnd: Window
    message: uint32
    wParam: uint
    lParam: int
    time: int32
    pt: Point
const
  inputStructSize = 28
  INPUT_MOUSE = 0
  INPUT_KEYBOARD = 1
  MOUSEEVENTF_ABSOLUTE = 0x8000
  MOUSEEVENTF_LEFTDOWN = 0x0002
  MOUSEEVENTF_LEFTUP = 0x0004
  MOUSEEVENTF_RIGHTDOWN = 0x0008
  MOUSEEVENTF_RIGHTUP = 0x0010
  MOUSEEVENTF_MIDDLEDOWN = 0x0020
  MOUSEEVENTF_MIDDLEUP = 0x0040
  KEYEVENTF_KEYUP = 0x0002
  KEYEVENTF_UNICODE = 0x0004
  SWP_NOSIZE = 0x0001.uint32
  SWP_NOMOVE = 0x0002.uint32
  SWP_NOACTIVATE = 0x0010.uint32
  #SW_SHOWNORMAL = 1.uint32
  SW_RESTORE = 9.uint32
  WM_HOTKEY = 0x0312

when useWinUnicode:
  type WinString = WideCString ## ``cstring`` when ``useWinAnsi`` defined,
  ## ``WideCString`` otherwise.
else:
  type WinString = cstring ## ``cstring`` when ``useWinAnsi`` defined,
  ## ``WideCString`` otherwise.

# proc newWinString(str: string): WinString =
#   if str == nil:
#     result = nil
#   else:
#     when useWinUnicode:
#       result = newWideCString(str)
#     else:
#       result = cstring(str)

when defined(automestatic):
  {.push callConv: stdcall.} # 1
else:
  {.push callConv: stdcall, dynlib: "kernel32".} # 2


proc sleep(dwMilliseconds: DWORD): void {.importc: "Sleep".}

proc getCurrentThreadId(): DWORD {.importc: "GetCurrentThreadId".}


when not defined(automestatic):
  {.pop.} # 2
  {.push callConv: stdcall, dynlib: "user32".} # 2

proc getCursorPos(lpPoint: ptr POINT): WINBOOL {.importc: "GetCursorPos".}

proc setCursorPos(x: int, y: int): WINBOOL {.importc: "SetCursorPos".}

proc sendInput(nInputs: uint, pInputs: pointer, cbSize: int): uint
  {.importc: "SendInput".}

proc getMessageExtraInfo(): pointer {.importc: "GetMessageExtraInfo".}

# https://msdn.microsoft.com/en-us/library/windows/desktop/ms633539(v=vs.85).aspx
# proc setForegroundWindow(hWnd: Window): WINBOOL
#   {.importc: "SetForegroundWindow".}

# proc mapVirtualKey(uCode, uMapType: uint32): uint32
#   {.importc: "MapVirtualKeyA".}

proc wEnumWindows(
    lpEnumFunc: proc(hwnd: Window, lParam: pointer): WINBOOL {.stdcall.},
    lParam: pointer): WINBOOL {.importc: "EnumWindows".}

proc getWindowThreadProcessId(hWnd: Window, lpdwProcessId: ptr DWORD): DWORD 
  {.importc: "GetWindowThreadProcessId".}

proc attachThreadInput(idAttach, idAttachTo: DWORD, fAttach: WINBOOL): WINBOOL
  {.importc: "AttachThreadInput".}

proc setFocus(hWnd: Window): Window {.importc: "SetFocus".}

proc getWindowText(hWnd: Window, lpString: pointer, nMaxCount: int): int
  {.importc: "GetWindowTextA".}

proc getWindowRect(hWnd: Window, lpRect: ptr RECT): WINBOOL
  {.importc: "GetWindowRect".}

proc getClientRect(hWnd: Window, lpRect: ptr RECT): WINBOOL
  {.importc: "GetClientRect".}

proc isIconic(hWnd: Window): WINBOOL {.importc: "IsIconic".}
  ## Determines whether the specified window is minimized (iconic).

proc isZoomed(hWnd: Window): WINBOOL {.importc: "IsZoomed".}
  ## not zoomed => 0, zoomed => != 0

proc setWindowPos(hWnd, hWndInsertAfter: Window, x, y, cx, cy: int,
    flags: uint32): WINBOOL {.importc: "SetWindowPos".}

proc getWindowPlacement(hWnd: Window, lpwndpl: ptr WINDOWPLACEMENT): WINBOOL
  {.importc: "GetWindowPlacement".}

proc setWindowPlacement(hWnd: Window, lpwndpl: ptr WINDOWPLACEMENT): WINBOOL
  {.importc: "SetWindowPlacement".}

proc windowFromPoint(Point: Point): Window {.importc: "WindowFromPoint".}

proc registerHotKey(hWnd: Window, id: Hotkey, fsModifiers: KeyboardModifiers,
    vk: uint32): WINBOOL {.importc: "RegisterHotKey".}

proc unregisterHotKey(hWnd: Window, id: Hotkey): WINBOOL
  {.importc: "UnregisterHotKey".}

proc getMessage(lpMsg: ptr MSG, hWnd: Window, wMsgFilterMin,
    wMsgFilterMax: uint32): WINBOOL {.importc: "GetMessageA".}

proc isWindow(hWnd: Window): WINBOOL
  {.importc: "IsWindow".}
# proc peekMessage(lpMsg: ptr MSG, hWnd: Window, wMsgFilterMin,
#     wMsgFilterMax: uint32, wRemoveMsg: uint32): WINBOOL
#   {.importc: "PeekMessageA".}

{.pop.} # 1