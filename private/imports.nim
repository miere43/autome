import winlean, dynlib

type
  Point* {.pure, final.} = tuple
    x: int32
    y: int32

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

## Retrieves the position of the mouse cursor, in screen coordinates.
proc getCursorPos*(lpPoint: ptr POINT): WINBOOL 
  {.stdcall, dynlib: "user32", importc: "GetCursorPos".}

proc setCursorPos*(x: int, y: int): WINBOOL
  {.stdcall, dynlib: "user32", importc: "SetCursorPos".}

proc sleep*(dwMilliseconds: DWORD): void
  {.stdcall, dynlib: "kernel32", importc: "Sleep".}

when useWinUnicode:
  proc findWindow*(lpClassName, lpWindowName: WinString): Handle
    {.stdcall, dynlib: "user32", importc: "FindWindowW".}
