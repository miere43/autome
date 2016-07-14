import strutils

proc minimized*(h: Window): bool =
  ## determines whether a window is minimized.
  return isIconic(h) != 0

proc maximized*(h: Window): bool =
  ## determines whether a window is maximized.
  return isZoomed(h) != 0

proc restore*(h: Window): Window {.sideEffect, discardable.} =
  ## restores window from minimized or maximized state or both. As result window
  ## is getting ## unminimized and unmaximized, its previous position before
  ## minimization or maximization gets restored. If window is not
  ## minimized or maximized, nothing will happen.
  ##
  ## When window gets restores from minimized state, it will gain focus,
  ## but restoring from maximized state doesn't give focus. Already showing
  ## window also does not receive focus.
  var wp = WINDOWPLACEMENT(length: sizeof(WINDOWPLACEMENT).uint32)
  echo "gwp", getWindowPlacement(h, wp.addr)
  wp.flags = 0
  wp.showCmd = SW_RESTORE
  echo setWindowPlacement(h, wp.addr)
  h

proc unminimize*(h: Window): Window {.inline, sideEffect, discardable.} =
  ## unminimizes window if it is minimized. Does nothing otherwise.
  if minimized(h):
    restore(h)
  h

proc unmaximize*(h: Window): Window {.inline, sideEffect, discardable.} =
  ## unmaximizes window if it is maximized. Does nothing otherwise.
  if maximized(h):
    restore(h)
  h

# proc valid*(w: WindowRef): bool =
#   w.Window != 0

proc title*(Window: Window, cap: int = 96): string =
  ## returns title of the window. Variable `cap` specifies how much bytes
  ## will be allocated for title string. If window title has `length >= cap`,
  ## returned window title will be trimmed to `cap - 1` characters.
  result = newStringOfCap(cap)
  var len = getWindowText(Window, result[0].addr, cap)
  setLen(result, len)

proc findWindowEnumProc(hwnd: Window, lParam: pointer): WINBOOL {.stdcall.} =
  var res = cast[ptr tuple[findstr: string, hwndPtr: ptr Window]](lParam)
  if hwnd.title.contains(res.findstr):
    res[].hwndPtr[] = hwnd
    return 0
  return 1

proc findWindow*(search: string): Window =
  ## returns first window which contains following string.
  var res: tuple[findstr: string, hwndPtr: ptr Window] =
    (findstr: search, hwndPtr: result.addr)
  discard wEnumWindows(findWindowEnumProc, res.addr)
  #imports.findWindow(newWinString(title), newWinString(class))

proc windowAt*(pos: Point): Window =
  ## returns window at pixel `pos`. If there are no window at `pos`, ``OSError``
  ## is raised.
  result = windowFromPoint(pos)
  if result == 0.Window:
    raise newException(OSError, "there are no window at " & $pos)

proc enumWindowsProc(hwnd: Window, lParam: pointer): WINBOOL {.stdcall.} =
  #echo "got hwnd: ", toHex(hwnd)
  var res: ptr seq[Window] = cast[ptr seq[Window]](lParam)
  res[].add(hwnd)
  return 1

proc enumWindows*(): seq[Window] =
  ## enumerates all opened windows, including hidden system windows.
  result = @[]
  discard wEnumWindows(enumWindowsProc, result.addr)

proc pos*(h: Window): Point =
  ## returns window position relative to upper-left corner.
  ## If window is minimized, ``OSError`` is raised.
  if minimized(h):
    raise newException(OSError, "window is minimized")
  var rect: RECT
  discard getWindowRect(h, rect.addr)
  return (x: rect.left, y: rect.top)

proc size*(h: Window): tuple[w: int32, h: int32] =
  ## returns width and height of the window including window borders.
  ## ``May report wrong values.``
  var wp = WINDOWPLACEMENT(length: sizeof(WINDOWPLACEMENT).uint32)
  discard getWindowPlacement(h, wp.addr)
  return (w: wp.rcNormalPosition.right - wp.rcNormalPosition.left,
    h: wp.rcNormalPosition.bottom - wp.rcNormalPosition.top)

proc clientsize*(h: Window): tuple[w: int32, h: int32] =
  ## returns width and height of the window without window borders aka
  ## actual window size.
  ## ``May report wrong values.``
  #if minimized(h):
  #  raise newException(OSError, "window is minimized")
  var rect: RECT
  discard getClientRect(h, rect.addr)
  return (w: rect.right - rect.left, h: rect.bottom - rect.top)

proc move*(window: Window, x, y: int): Window {.sideEffect, discardable.} =
  ## moves window to new position.
  discard setWindowPos(window, 0.Window, x, y, 0, 0, SWP_NOSIZE)
  window

proc resize*(window: Window, w, h: int): Window {.sideEffect, discardable.} =
  ## resizes window.
  #if minimized(h):
  #  raise newException(OSError, "window is minimized")
  #echo "minimized: ", minimized(h)
  discard setWindowPos(window, 0.Window, 0, 0, w, h, SWP_NOMOVE)
  window

template attachBase(h: Window, attach: WINBOOL): Window =
  var windowThread = getWindowThreadProcessId(h, nil)
  #if getWindowThreadProcessId(h, windowThread.addr) == 0:
  #  raise newException(OSError, "unable to get window thread process id")
  if attachThreadInput(getCurrentThreadId(), windowThread, attach) == 0:
    echo getLastError()
    raise newException(OSError, "unable to attach thread input to window: " &
      getOSErrorMsg())
  h

proc attach*(h: Window): Window {.sideEffect, discardable.} =
  ## attaches current thread to window thread so ``show()`` and ``foreground()``
  ## procs can be used with window.
  attachBase(h, 1.WINBOOL)

proc detach*(h: Window): Window {.sideEffect, discardable.} =
  ## detaches current thread from window.
  attachBase(h, 0.WINBOOL)

# proc foreground*(h: Window) =
#   ## places the window on top of Z-order. Window can be still covered by
#   ## topmost windows if specified window is not topmost.
#   if 0 == wSetForegroundWindow(h):
#     raise newException(OSError, "cannot bring window to foreground")

proc tofront*(h: Window): Window {.sideEffect, discardable.} =
  ## places the window at the top of Z-order.
  const HWND_TOP = 0.Window
  if 0 == setWindowPos(h, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or
      SWP_NOACTIVATE):
    raise newException(OSError, "unable to move window to front")
  h

proc focus*(h: Window): Window {.sideEffect, discardable.} =
  ## gains focus to the window.
  if setFocus(h) == 0.Window:
    raise newException(OSError, "unable to set focus, did you " &
      "forgot to call `attach()`?: " & getOSErrorMsg())
  h

proc show*(h: Window): Window {.sideEffect, discardable.} =
  ## unminimizes window if it is not in normal state, brings it to
  ## front and focuses on it, basically, window is now on top above all other
  ## windows,`` howerer, it may be covered by topmost windows.``
  unminimize(h)
  focus(h)
  tofront(h)
  h

proc tobottom*(h: Window): Window {.sideEffect, discardable.} =
  ## places the window at the bottom of Z-order. ``Window will lose it's
  ## topmost status.``
  const HWND_BOTTOM = 1.Window
  if 0 == setWindowPos(h, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or
      SWP_NOACTIVATE):
    raise newException(OSError, "unable to move window to bottom")
  h

proc topmost*(h: Window, topmost: bool = true): Window
    {.sideEffect, discardable.} =
  ## enables or disables topmost status of the window. When topmost status
  ## disabled, window will be placed on top of Z-order before topmost windows.
  const
    HWND_TOPMOST = (-1).Window
    HWND_NOTOPMOST = (-2).Window
  if topmost:
    if 0 == setWindowPos(h, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or
        SWP_NOACTIVATE):
      raise newException(OSError, "unable to make window topmost")
  else:
    if 0 == setWindowPos(h, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or
        SWP_NOACTIVATE):
      raise newException(OSError, "unable to make window non-topmost")
  h