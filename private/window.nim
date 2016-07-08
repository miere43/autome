import strutils

proc minimized*(h: Handle): bool =
  ## determines whether a window is minimized.
  return isIconic(h) != 0

proc maximized*(h: Handle): bool =
  ## determines whether a window is maximized.
  return isZoomed(h) != 0

proc show*(h: Handle): Handle {.discardable.} =
  ## restores window from minimized or maximized state or both. As result window
  ## is getting ## unminimized and unmaximized, its previous position before
  ## minimization or maximization gets restored. If window is not
  ## minimized or maximized, nothing will happen.
  ##
  ## When window gets restores from minimized state, it will gain focus,
  ## but restoring from maximized state doesn't give focus. Already showing
  ## window will also dont receive focus.
  var wp = WINDOWPLACEMENT(length: sizeof(WINDOWPLACEMENT).uint32)
  echo "gwp", getWindowPlacement(h, wp.addr)
  wp.flags = 0
  wp.showCmd = SW_RESTORE
  echo setWindowPlacement(h, wp.addr)
  h

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

proc pos*(h: Handle): Point =
  ## returns window position relative to upper-left corner.
  ## If window is minimized, ``OSError`` is raised.
  if minimized(h):
    raise newException(OSError, "window is minimized")
  var rect: RECT
  discard getWindowRect(h, rect.addr)
  return (x: rect.left, y: rect.top)

proc size*(h: Handle): tuple[w: int32, h: int32] =
  ## returns width and height of the window including window borders.
  var wp = WINDOWPLACEMENT(length: sizeof(WINDOWPLACEMENT).uint32)
  discard getWindowPlacement(h, wp.addr)
  return (w: wp.rcNormalPosition.right - wp.rcNormalPosition.left,
    h: wp.rcNormalPosition.bottom - wp.rcNormalPosition.top)

proc clientsize*(h: Handle): tuple[w: int32, h: int32] =
  ## returns width and height of the window ``without window border`` aka
  ## actual window size. If window is minimized, ``OSError`` is raised.
  #if minimized(h):
  #  raise newException(OSError, "window is minimized")
  var rect: RECT
  discard getClientRect(h, rect.addr)
  return (w: rect.right - rect.left, h: rect.bottom - rect.top)

proc move*(handle: Handle, x, y: int): Handle {.discardable.} =
  echo "move: ", setWindowPos(handle, 0.Handle, x, y, 0, 0, SWP_NOSIZE)
  handle

proc resize*(handle: Handle, w, h: int): Handle {.discardable.} =
  #if minimized(h):
  #  raise newException(OSError, "window is minimized")
  echo "minimized: ", minimized(h)
  echo "resize: ", setWindowPos(handle, 0.Handle, 0, 0, w, h, SWP_NOMOVE)
  handle

proc foreground*(h: Handle) =
  if 0 == wSetForegroundWindow(h):
    raise newException(OSError, "cannot bring window to foreground")

