import strutils

proc valid*(w: WindowRef): bool =
  w.handle != 0

proc bringToFront*(handle: Handle): bool =
  ## brings windows to the front. Nothing will happen if window is minimized.
  imports.setForegroundWindow(handle).bool

proc enumWindowsProc(hwnd: Handle, lParam: pointer): WINBOOL {.stdcall.} =
  #echo "got hwnd: ", toHex(hwnd)
  var res: ptr seq[Handle] = cast[ptr seq[Handle]](lParam)
  res[].add(hwnd)
  return 1

proc enumWindows*(): seq[Handle] =
  result = @[]
  discard wEnumWindows(enumWindowsProc, result.addr)

proc title*(handle: Handle): string =
  const cap = 96
  result = newStringOfCap(cap)
  var len = getWindowText(handle, result[0].addr, cap)
  setLen(result, len)
  #  result = ""

proc findWindowEnumProc(hwnd: Handle, lParam: pointer): WINBOOL {.stdcall.} =
  var res = cast[ptr tuple[findstr: string, hwndPtr: ptr Handle]](lParam)
  var t = hwnd.title
  #var chars: seq[char] = @[]
  #echo t, " -> ", len(t)
  if hwnd.title.contains(res.findstr):
    res[].hwndPtr[] = hwnd
    return 0
  return 1

proc findWindow*(search: string): Handle =
  ## returns first window which contains following string.
  var res: tuple[findstr: string, hwndPtr: ptr Handle] =
    (findstr: search, hwndPtr: result.addr)
  discard wEnumWindows(findWindowEnumProc, res.addr)
  #imports.findWindow(newWinString(title), newWinString(class))
