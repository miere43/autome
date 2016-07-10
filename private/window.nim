import strutils

proc minimized*(h: Handle): bool =
  ## determines whether a window is minimized.
  return isIconic(h) != 0

proc maximized*(h: Handle): bool =
  ## determines whether a window is maximized.
  return isZoomed(h) != 0

proc restore*(h: Handle): Handle {.discardable.} =
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

proc unminimize*(h: Handle): Handle {.inline, discardable.} =
  ## unminimizes window if it is minimized. Does nothing otherwise.
  if minimized(h):
    restore(h)
  h

proc unmaximize*(h: Handle): Handle {.inline, discardable.} =
  ## unmaximizes window if it is maximized. Does nothing otherwise.
  if maximized(h):
    restore(h)
  h

# proc valid*(w: WindowRef): bool =
#   w.handle != 0

proc title*(handle: Handle, cap: int = 96): string =
  ## returns title of the window. Variable `cap` specifies how much bytes
  ## will be allocated for title string. If window title has `length >= cap`,
  ## returned window title will be trimmed to `cap - 1` characters.
  result = newStringOfCap(cap)
  var len = getWindowText(handle, result[0].addr, cap)
  setLen(result, len)

proc findWindowEnumProc(hwnd: Handle, lParam: pointer): WINBOOL {.stdcall.} =
  var res = cast[ptr tuple[findstr: string, hwndPtr: ptr Handle]](lParam)
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

proc windowAt*(pos: Point): Handle =
  ## returns window at pixel `pos`. If there are no window at `pos`, ``OSError``
  ## is raised.
  result = windowFromPoint(pos)
  if result == 0:
    raise newException(OSError, "there are no window at " & $pos)

proc enumWindowsProc(hwnd: Handle, lParam: pointer): WINBOOL {.stdcall.} =
  #echo "got hwnd: ", toHex(hwnd)
  var res: ptr seq[Handle] = cast[ptr seq[Handle]](lParam)
  res[].add(hwnd)
  return 1

proc enumWindows*(): seq[Handle] =
  ## enumerates all opened windows, including hidden system windows.
  result = @[]
  discard wEnumWindows(enumWindowsProc, result.addr)

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
  ## moves window to new position.
  discard setWindowPos(handle, 0.Handle, x, y, 0, 0, SWP_NOSIZE)
  handle

proc resize*(handle: Handle, w, h: int): Handle {.discardable.} =
  ## resizes window.
  #if minimized(h):
  #  raise newException(OSError, "window is minimized")
  echo "minimized: ", minimized(h)
  echo "resize: ", setWindowPos(handle, 0.Handle, 0, 0, w, h, SWP_NOMOVE)
  handle

template attachBase(h: Handle, attach: WINBOOL): Handle =
  var windowThread = getWindowThreadProcessId(h, nil)
  #if getWindowThreadProcessId(h, windowThread.addr) == 0:
  #  raise newException(OSError, "unable to get window thread process id")
  if attachThreadInput(getCurrentThreadId(), windowThread, attach) == 0:
    echo getLastError()
    raise newException(OSError, "unable to attach thread input to window: " &
      getOSErrorMsg())
  h

proc attach*(h: Handle): Handle {.discardable.} =
  ## attaches current thread to window thread so ``show()`` and ``foreground()``
  ## procs can be used with window.
  attachBase(h, 1.WINBOOL)

proc detach*(h: Handle): Handle {.discardable.} =
  ## detaches current thread from window.
  attachBase(h, 0.WINBOOL)

# proc foreground*(h: Handle) =
#   ## places the window on top of Z-order. Window can be still covered by
#   ## topmost windows if specified window is not topmost.
#   if 0 == wSetForegroundWindow(h):
#     raise newException(OSError, "cannot bring window to foreground")

proc tofront*(h: Handle): Handle {.discardable.} =
  ## places the window at the top of Z-order.
  const HWND_TOP = 0.Handle
  if 0 == setWindowPos(h, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or
      SWP_NOACTIVATE):
    raise newException(OSError, "unable to move window to front")
  h

proc focus*(h: Handle): Handle {.discardable.} =
  ## gains focus to the window.
  if setFocus(h) == 0:
    raise newException(OSError, "unable to set focus, did you " &
      "forgot to call `attach()`?: " & getOSErrorMsg())
  h

proc show*(h: Handle): Handle {.discardable.} =
  ## unminimizes window if it is not in normal state, brings it to
  ## front and focuses on it, basically, window is now on top above all other
  ## windows,`` howerer, it may be covered by topmost windows.``
  unminimize(h)
  focus(h)
  tofront(h)
  h

proc tobottom*(h: Handle): Handle {.discardable.} =
  ## places the window at the bottom of Z-order. ``Window will lose it's
  ## topmost status.``
  const HWND_BOTTOM = 1.Handle
  if 0 == setWindowPos(h, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or
      SWP_NOACTIVATE):
    raise newException(OSError, "unable to move window to bottom")
  h

proc topmost*(h: Handle, topmost: bool = true): Handle {.discardable.} =
  ## enables or disables topmost status of the window. When topmost status
  ## disabled, window will be placed on top of Z-order before topmost windows.
  const
    HWND_TOPMOST = -1.Handle
    HWND_NOTOPMOST = -2.Handle
  if topmost:
    if 0 == setWindowPos(h, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or
        SWP_NOACTIVATE):
      raise newException(OSError, "unable to make window topmost")
  else:
    if 0 == setWindowPos(h, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or
        SWP_NOACTIVATE):
      raise newException(OSError, "unable to make window non-topmost")
  h