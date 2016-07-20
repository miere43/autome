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
  #echo "gwp", getWindowPlacement(h, wp.addr)
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

proc title*(window: Window, cap: int = 96): string =
  ## returns title of the window. Variable `cap` specifies how much bytes
  ## will be allocated for title string. If window title has `length >= cap`,
  ## returned window title will be trimmed to `cap - 1` characters.
  result = newStringOfCap(cap)
  var len = getWindowText(window, result[0].addr, cap)
  if len == 0:
    return ""
  setLen(result, len)

proc findWindowEnumProc(hwnd: Window, lParam: pointer): WINBOOL {.stdcall.} =
  var res = cast[
    ptr tuple[findstr, titlebuf: string, hwndPtr: ptr Window]](lParam)

  var len = getWindowText(hwnd, res[].titlebuf[0].addr, 255)
  if len == 0:
    return 1
  setLen(res[].titlebuf, len)

  if res[].titlebuf.contains(res.findstr):
    res[].hwndPtr[] = hwnd # set result variable of findWindow proc.
    return 0
  return 1

proc findWindow*(search: string): Window =
  ## returns first window which contains following string. Returns ``Window(0)``
  ## if not found.
  var res: tuple[findstr, titlebuf: string, hwndPtr: ptr Window] =
    (findstr: search, titlebuf: newStringOfCap(255), hwndPtr: result.addr)
  discard wEnumWindows(findWindowEnumProc, res.addr)
  #imports.findWindow(newWinString(title), newWinString(class))

proc waitForWindow*(search: string, timeout: int,
    pollDelay: int32 = 100): Window {.sideEffect.} =
  ## blocks current thread until window containing string `search` has been
  ## found or until `timeout` (milliseconds) elapses, polling for window each
  ## `pollDelay` milliseconds. Returns ``Window(0)`` if `timeout` has elapsed
  ## and no window was found.
  # todo test with timeout = 0 and timeout < 0
  var timeleft = timeout
  while timeleft >= 0:
    result = findWindow(search)
    if result == 0.Window:
      timeleft = timeleft - pollDelay
      sleep(pollDelay)
    else:
      break

proc waitForWindowDestroy*(window: Window, timeout: int,
    pollDelay: int32 = 100): bool {.sideEffect.} =
  ## blocks current thread until ``window`` gets destroyed. This proc may
  ## not catch destroy event because window handles are recycled and thus
  ## old window handle may point to the new window handle. Returns ``true``
  ## when window has been destroyed and ``false`` when ``timeout`` elapsed.
  var timeleft = timeout
  while timeleft >= 0:
    if isWindow(window) != 0:
      timeleft = timeleft - pollDelay
      sleep(pollDelay)
    else:
      return true
  return false

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
  ## If window is minimized or proc fails, ``OSError`` is raised.
  if minimized(h):
    raise newException(OSError, "window is minimized")
  var rect: RECT
  if getWindowRect(h, rect.addr) == 0:
    raise newException(OSError, "unable to get window pos: " & getOSErrorMsg())
  return (x: rect.left, y: rect.top)

proc size*(h: Window): tuple[w: int32, h: int32] =
  ## returns width and height of the window including window borders.
  ## If proc fails, ``OSError`` raised.
  ## ``May report wrong values.``
  var wp = WINDOWPLACEMENT(length: sizeof(WINDOWPLACEMENT).uint32)
  if getWindowPlacement(h, wp.addr) == 0:
    raise newException(OSError, "unable to get window size: " & getOSErrorMsg())
  return (w: wp.rcNormalPosition.right - wp.rcNormalPosition.left,
    h: wp.rcNormalPosition.bottom - wp.rcNormalPosition.top)

proc clientsize*(h: Window): tuple[w: int32, h: int32] =
  ## returns width and height of the window without window borders aka
  ## actual window size. If proc fails, ``OSError`` raised.
  ## ``May report wrong values.``
  var rect: RECT
  if getClientRect(h, rect.addr) == 0:
    raise newException(OSError, "unable to get window client area size:" &
      getOSErrorMsg())
  return (w: rect.right - rect.left, h: rect.bottom - rect.top)

proc move*(window: Window, x, y: int): Window {.sideEffect, discardable.} =
  ## moves window to new position. If proc fails, ``OSError`` raised.
  if setWindowPos(window, 0.Window, x, y, 0, 0, SWP_NOSIZE) == 0:
    raise newException(OSError, "unable to move window: " & getOSErrorMsg())
  window

proc resize*(window: Window, w, h: int): Window {.sideEffect, discardable.} =
  ## resizes window. If proc fails, ``OSError`` raised.
  if setWindowPos(window, 0.Window, 0, 0, w, h, SWP_NOMOVE) == 0:
    raise newException(OSError, "unable to resize window: " & getOSErrorMsg())
  window

template attachBase(h: Window, attach: WINBOOL): Window =
  var windowThread = getWindowThreadProcessId(h, nil)
  if attachThreadInput(getCurrentThreadId(), windowThread, attach) == 0:
    echo getLastError()
    raise newException(OSError, "unable to attach/detach thread input " & 
      "to window: " & getOSErrorMsg())
  h

proc attach*(h: Window): Window {.sideEffect, discardable.} =
  ## attaches current thread to window thread so `show()<#show>`_ and 
  ## `focus()<#focus>`_ procs can be used with window.
  attachBase(h, 1.WINBOOL)

proc detach*(h: Window): Window {.sideEffect, discardable.} =
  ## detaches current thread from window.
  attachBase(h, 0.WINBOOL)

proc tofront*(window: Window): Window {.sideEffect, discardable.} =
  ## puts `window` on top of Z-order.  If proc fails, ``OSError`` raised.
  const HWND_TOP = 0.Window
  if 0 == setWindowPos(window, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or
      SWP_NOACTIVATE):
    raise newException(OSError, "unable to move window to front")
  window

proc focus*(window: Window): Window {.sideEffect, discardable.} =
  ## gains focus to the `window`. If proc fails or current thread is not
  ## attached to thread of `window`, ``OSError`` raised.
  if setFocus(window) == 0.Window:
    raise newException(OSError, "unable to set focus, did you " &
      "forgot to call `attach()`?: " & getOSErrorMsg())
  window

proc show*(window: Window): Window {.sideEffect, discardable.} =
  ## unminimizes window if it is not in normal state, brings it to
  ## front and focuses on it, basically, window is now on top above all other
  ## windows, howerer, it still may be covered by topmost windows.
  unminimize(window)
  focus(window)
  tofront(window)
  window

proc tobottom*(window: Window): Window {.sideEffect, discardable.} =
  ## puts the `window` on the bottom of Z-order. Window will lose it's
  ## topmost status. If proc fails, ``OSError`` raised.
  const HWND_BOTTOM = 1.Window
  if 0 == setWindowPos(window, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or
      SWP_NOACTIVATE):
    raise newException(OSError, "unable to move window to the bottom")
  window

proc topmost*(window: Window, topmost: bool = true): Window
    {.sideEffect, discardable.} =
  ## enables or disables topmost status of the `window`. When topmost status
  ## disabled, window will be placed on top of Z-order before topmost windows.
  ## If proc fails, ``OSError`` raised.
  const
    HWND_TOPMOST = (-1).Window
    HWND_NOTOPMOST = (-2).Window
  if topmost:
    if 0 == setWindowPos(window, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or
        SWP_NOSIZE or SWP_NOACTIVATE):
      raise newException(OSError, "unable to make window topmost")
  else:
    if 0 == setWindowPos(window, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE or
        SWP_NOSIZE or SWP_NOACTIVATE):
      raise newException(OSError, "unable to make window non-topmost")
  window