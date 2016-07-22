proc registerNotify*(): bool =
  ## registers dummy tray icon to status bar so you can send notifications
  ## to Windows. If this proc returns ``true``, you can use
  ## `notify<#notify>`_ proc to send notifications. If you don't unregister
  ## tray icon with `unregisterNotify()<#unregisterNotify>`_, you will not
  ## able to register it again in when program launches next time.
  var data = NOTIFYICONDATAA()
  data.cbSize = sizeof(NOTIFYICONDATAA).DWORD
  data.hWnd = 0.Window
  data.uID = 666.uint32
  data.uFlags = 0.uint32
  # this is ASCII version
  data.uVersion = 4

  if 0 == shellNotifyIconA(NIM_ADD, data.addr):
    return false
  return 1 == shellNotifyIconA(NIM_SETVERSION, data.addr)

proc notify*(msg: string, title, tip: string = nil): bool {.discardable.} =
  ## sends notification to Windows desktop notification area. Maximum string
  ## length for ``msg`` is 255, for ``title`` - 64, for ``tip`` - 128. Before
  ## calling this proc you should call
  ## `registerNotify()<#registerNotify>`_. Returns ``false`` if length of
  ## ``msg``, ``title`` or ``tip`` is more than allowed or when unable to send a
  ## notification.
  if msg == nil or len(msg) >= 256:
    return false
  if title != nil and len(title) >= 64:
    return false
  if tip != nil and len(tip) >= 128:
    return false

  var data = NOTIFYICONDATAA()
  data.cbSize = sizeof(NOTIFYICONDATAA).DWORD
  data.hWnd = 0.Window
  data.uID = 666.uint32
  data.uVersion = 4
  data.uFlags = NIF_INFO
  if tip != nil:
    data.uFlags = data.uFlags or NIF_TIP or NIF_SHOWTIP
  # this is ASCII version
  copyMem(data.szInfo[0].addr, msg[0].unsafeAddr, len(msg) + 1)

  if title != nil:
    copyMem(data.szInfoTitle[0].addr, title[0].unsafeAddr, len(title) + 1)
  if tip != nil:
    copyMem(data.szTip[0].addr, tip[0].unsafeAddr, len(tip) + 1)

  return 1 == shellNotifyIconA(NIM_MODIFY, data.addr)

proc unregisterNotify*(): bool =
  ## unregisters tray icon from status bar that was registered by 
  ## `registerNotify<#registerNotify()>`_ proc. 
  var data = NOTIFYICONDATAA()
  data.cbSize = sizeof(NOTIFYICONDATAA).DWORD
  data.hWnd = 0.Window
  data.uID = 666.uint32
  data.uFlags = 0.uint32

  return 1 == shellNotifyIconA(NIM_DELETE, data.addr)
