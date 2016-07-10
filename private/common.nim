proc getOSErrorMsg(): string =
  ## Retrieves the operating system's error flag, ``errno``.
  ## On Windows ``GetLastError`` is checked before ``errno``.
  ## Returns "" if no error occurred.
  result = ""
  var err = getLastError()
  if err != 0'i32:
    when useWinUnicode:
      var msgbuf: WideCString
      if formatMessageW(0x00000100 or 0x00001000 or 0x00000200 or 0x000000FF,
                        nil, err, 0, addr(msgbuf), 0, nil) != 0'i32:
        result = $msgbuf
        if msgbuf != nil: localFree(cast[pointer](msgbuf))
    else:
      var msgbuf: cstring
      if formatMessageA(0x00000100 or 0x00001000 or 0x00000200 or 0x000000FF,
                        nil, err, 0, addr(msgbuf), 0, nil) != 0'i32:
        result = $msgbuf
        if msgbuf != nil: localFree(msgbuf)

# template raiseErrorIf(cond: expr): stmt =
#   if cond:
#     raise newException(OSError, getOSErrorMsg())

# template raiseGenericOSError(cond: expr, msg: string): stmt =
#   if cond:
#     raise newException(OSError, msg)
    
proc wait*(ms: int): void {.inline, sideEffect.} =
  ## suspends the execution of current thread
  ## until the time-out interval elapses. Time is in milliseconds.
  imports.sleep(ms.DWORD)