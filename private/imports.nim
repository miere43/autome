import winlean, dynlib

type
  Point* {.pure, final.} = tuple
    x: int32
    y: int32
  MOUSEINPUT* {.pure, final.} = object
    kind*: DWORD
    dx*: LONG
    dy*: LONG
    mouseData*: DWORD
    dwFlags*: DWORD
    time*: DWORD
    dwExtraInfo*: pointer
  MarshalArray = array[0..100_000, byte]

const
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

when useWinUnicode:
  type WinString* = WideCString
else:
  type WinString* = cstring

proc newWinString*(str: string): WinString =
  when useWinUnicode:
    if str == nil:
      result = nil
    else:
      result = newWideCString(str)
  else:
    result = cstring(str)

#proc allocMarshalArray[T](numEntries: int): MarshalArray =
#  result = cast[MarshalArray](alloc())

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

when useWinUnicode:
  proc findWindow*(lpClassName, lpWindowName: WinString): Handle
    {.stdcall, dynlib: "user32", importc: "FindWindowW".}
