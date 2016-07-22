proc genHotkeyID(): Hotkey =
  var hnum {.global.}: int = 1
  result = Hotkey(hnum)
  inc(hnum)

proc registerHotkey*(key: uint32, mods: KeyboardModifiers = {}): Hotkey
    {.sideEffect.} =
  ## registers hotkey that can be invoked globally. Use ``waitForHotkey`` proc
  ## to wait until hotkey is pressed. `key` is virtual-key code, which is 
  ## unfortunately does not match ASCII key codes. List of virtual-key codes is
  ## `available on MSDN<http://tinyurl.com/virtkeycodes>`_. `mods` can be
  ## combined with ``or`` operator. Use ``modNoRepeat``, so that keyboard
  ## auto-repeat does not yield multiple events.
  ##
  ## If there are global hotkey with same signature already registered in
  ## system by any another application, this proc will raise ``OSError``.
  ##
  ## .. code-block:: nim
  ##   let hk = registerHotkey(0x42, {modShift}) # 0x42 - virtual-key of `b`
  ##   waitForHotkey(hk)
  ##   echo "hotkey SHIFT+b invoked"
  ##
  ## Do not register hotkeys without modifiers because that will
  ## effectively block any key presses of button that specified as hotkey,
  ## for example, in Notepad.
  result = genHotkeyID()
  if 0 == registerHotKey(0.Window, result, mods, key.uint32):
    raise newException(OSError, "unable to register hotkey: " & getOSErrorMsg())

proc unregisterHotkey*(hotkey: Hotkey) {.sideEffect.} =
  ## unregisters hotkey that was registered using
  ## `registerHotkey<#registerHotkey>`_ proc.
  discard unregisterHotKey(0.Window, hotkey)

proc waitForHotkeys*(hotkeys: openArray[Hotkey],
    timeout: uint32 = 0): Hotkey {.sideEffect.} =
  ## blocks current thread until any hotkey in ``openArray[Hotkey]`` invoked.
  ## If ``timeout`` is more than 0, then this proc will return after hotkey
  ## invoked or until ``timeout`` in milliseconds has elapsed. This proc returns
  ## handle of hotkey that was invoked or ``Hotkey(-1)`` if ``timeout`` elapsed.
  var msg: MSG
  var status: WINBOOL
  var timer: uint32
  if timeout != 0:
    timer = setTimer(0.Window, 0, timeout, nil)
  while true:
    status = getMessageA(msg.addr, 0.Window, WM_TIMER, WM_HOTKEY)
    if status == -1:
      raise newException(OSError, "error while waiting for hotkey: " &
        getOSErrorMsg())
    if status == 0 or msg.message == WM_TIMER and msg.wParam == timer:
      result = Hotkey(-1)
      break
    if msg.message == WM_HOTKEY and msg.wParam.int.Hotkey in hotkeys:
      result = msg.wParam.int.Hotkey
      break
  if timeout != 0 and result.int > 0:
    discard killTimer(0.Window, uint(timer))

proc waitForHotkey*(hotkey: Hotkey, timeout: uint32 = 0): bool
    {.sideEffect, discardable.} =
  ## blocks current thread until `hotkey` is invoked. If ``timeout`` is 0, then
  ## this proc has no timeout. If ``timeout`` has elapsed, ``false`` returned,
  ##``true`` otherwise. Note that registering Ctrl+C hotkey will shadow console
  ## Ctrl+C interrupt.
  return waitForHotkeys([hotkey], timeout) != Hotkey(-1)