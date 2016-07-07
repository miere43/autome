type
  MouseButton = enum
    mLeft, mRight, mMiddle
  MouseState = enum
    msDown, msUp

proc pos*(m: MouseCtx): Point =
  discard getCursorPos(result.addr)

proc initMouseInput(x, y: LONG, dwFlags: DWORD,
    mouseData: DWORD = 0.DWORD): MOUSEINPUT {.inline, sideEffect.} =
  MOUSEINPUT(
    kind: INPUT_MOUSE,
    dx: x,
    dy: y,
    mouseData: mouseData,
    dwFlags: dwFlags,
    time: 0.DWORD,
    dwExtraInfo: getMessageExtraInfo())

proc mouseButtonToDownFlags(b: MouseButton): DWORD {.inline, gcsafe.} =
  result = case b
    of mLeft: MOUSEEVENTF_LEFTDOWN
    of mRight: MOUSEEVENTF_RIGHTDOWN
    of mMiddle: MOUSEEVENTF_MIDDLEDOWN

proc mouseButtonToUpFlags(b: MouseButton): DWORD {.inline, gcsafe.} =
  result = case b
    of mLeft: MOUSEEVENTF_LEFTUP
    of mRight: MOUSEEVENTF_RIGHTUP
    of mMiddle: MOUSEEVENTF_MIDDLEUP

proc mouseButtonToFlags(b: MouseButton, s: MouseState): DWORD {.gcsafe.} =
  result = case s
    of msDown: mouseButtonToDownFlags(b)
    of msUp: mouseButtonToUpFlags(b)

proc click*(m: MouseCtx, button: MouseButton, x, y: int32): MouseCtx
    {.discardable.} =
  ## emulates mouse press and release event.
  var inputs: array[2, MOUSEINPUT]
  inputs[0] = initMouseInput(x, y,
    MOUSEEVENTF_ABSOLUTE or mouseButtonToDownFlags(button))
  inputs[1] = initMouseInput(x, y,
    MOUSEEVENTF_ABSOLUTE or mouseButtonToUpFlags(button))
  let res = sendInput(len(inputs).uint, inputs[0].addr, sizeof(MOUSEINPUT))
  assert res == len(inputs).uint
  m

proc click*(m: MouseCtx, x, y: int32): MouseCtx {.inline, discardable.} =
  result = click(m, mLeft, x, y)

proc doubleclick*(m: MouseCtx): MouseCtx {.inline, discardable.} =
  ## emulates double mouse press and one release event.
  var (x, y) = m.pos()
  var inputs: array[4, MOUSEINPUT]
  inputs[0] = initMouseInput(x, y,
    MOUSEEVENTF_ABSOLUTE or mouseButtonToDownFlags(mLeft))
  inputs[1] = initMouseInput(x, y,
    MOUSEEVENTF_ABSOLUTE or mouseButtonToDownFlags(mLeft))
  inputs[2] = initMouseInput(x, y,
    MOUSEEVENTF_ABSOLUTE or mouseButtonToUpFlags(mLeft))
  let res = sendInput(len(inputs).uint, inputs[0].addr, sizeof(MOUSEINPUT))
  assert res == len(inputs).uint
  m

proc emit*(m: MouseCtx, button: MouseButton,
    events: varargs[MouseState]): MouseCtx {.discardable.} =
  # emit mouse press/release events at current mouse position.
  echo "varargs len: ", events.len
  var (x, y) = m.pos()
  var inputsLen = len(events)
  var inputs = cast[array[0..100, MOUSEINPUT]]
    (alloc(sizeof(MOUSEINPUT) * inputsLen))
  var i = 0
  for event in events:
    inputs[i] = initMouseInput(x, y,
      MOUSEEVENTF_ABSOLUTE or mouseButtonToFlags(button, event)) 
    inc(i)
  let res = sendInput(inputsLen.uint, inputs[0].addr, sizeof(MOUSEINPUT))
  dealloc(inputs.addr)
  assert res == inputsLen.uint
  m

proc move*(m: MouseCtx, x, y: int): MouseCtx {.discardable.} =
  discard setCursorPos(x, y)
  m

proc x*(m: MouseCtx): int {.inline.} =
  var p: POINT
  discard getCursorPos(p.addr)
  p.x

proc y*(m: MouseCtx): int {.inline.} =
  var p: POINT
  discard getCursorPos(p.addr)
  p.y

proc x*(m: MouseCtx, pos: int): MouseCtx {.inline, sideEffect, discardable.} =
  discard setCursorPos(pos, m.y)
  m

proc y*(m: MouseCtx, pos: int): MouseCtx {.inline, sideEffect, discardable.} =
  discard setCursorPos(m.x, pos)
  m

proc `x=`*(m: MouseCtx, pos: int) {.inline, sideEffect.} =
  m.x(pos)

proc `y=`*(m: MouseCtx, pos: int) {.inline, sideEffect.} =
  m.y(pos)

proc wait(m: MouseCtx, ms: int): MouseCtx {.inline, sideEffect.} =
  ## stops execution for `ms` milliseconds.
  wait(ms)
  m