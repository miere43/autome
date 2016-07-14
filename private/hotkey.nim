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
  ##   let hk = registerHotkey(0x42, modShift) # 0x42 - virtual-key code of `b`
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
  if 0 == unregisterHotKey(0.Window, hotkey):
    raise newException(OSError, "unable to unregister hotkey: " &
      getOSErrorMsg())

proc waitForHotkey*(hotkey: Hotkey) {.sideEffect.} =
  ## blocks current thread until `hotkey` is invoked. Using hotkey, unregistered
  ## with `unregisterHotkey<#unregisterHotkey>`_ proc will lock thread forever.
  # TODO: waitForHotkey with timeout.
  var msg: MSG
  var status: WINBOOL
  while true:
    status = getMessage(msg.addr, 0.Window, WM_HOTKEY, WM_HOTKEY)
    if status == -1:
      raise newException(OSError, "error while waiting for hotkey: " &
        getOSErrorMsg())
    if status == 0:
      break
    if msg.message == WM_HOTKEY and msg.wParam == hotkey.uint32:
      break