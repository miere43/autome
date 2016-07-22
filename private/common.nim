proc getOSErrorMsg(): string =
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
    
proc wait*(ms: int32): void {.inline, sideEffect.} =
  ## suspends the execution of current thread
  ## until the time-out interval elapses. Time is in milliseconds.
  sleep(ms.DWORD)

proc getPixel*(x, y: int): int32 =
  ## returns pixel color at `x` and `y`. High-order byte is always 0, next bytes
  ## are blue, green, and low-order byte is red (aka 0x00BBGGRR). If `x` or `y`
  ## are out of bounds, ``OSError`` raised.
  ##
  ## You can use `unpackColor()<#unpackColor>`_ proc to get tuple containing
  ## red, green and blue values in their respective bytes.
  var hdc = getDC(0.Window)
  var color = getPixel(hdc, x, y).int32
  if color == 0xFFFFFFFF:
    raise newException(OSError, "unable to get pixel color")
  color

proc unpackColor*(color: int32): tuple[r, g, b: byte] =
  ## unpacks color, encoded as ``int32``, to tuple.
  ## 0x00BBGGRR
  result.b = byte((color shl 8) shr 24)
  result.g = byte((color shl 16) shr 24)
  result.r = byte((color shl 24) shr 24)

proc desktopSize*(): tuple[width, height: int] =
  ## returns desktop size. This is not same as monitor size: if Windows runs
  ## in 640x480, but monitor is 1920x1080, returned value will be 640x480.
  var hdc = getDC(0.Window)
  result.width = getDeviceCaps(hdc, HORZRES)
  result.height = getDeviceCaps(hdc, VERTRES)


