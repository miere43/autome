type
  MouseButton = enum
    mLeft, mRight, mMiddle

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

proc click*(m: MouseCtx, button: MouseButton, x, y: int32): MouseCtx
    {.discardable.} =
  ## emulates mouse press and release event.
  var inputs: array[2, MOUSEINPUT]
  inputs[0] = MOUSEINPUT(
    kind: INPUT_MOUSE,
    dx: x,
    dy: y,
    mouseData: 0.DWORD,
    dwFlags: MOUSEEVENTF_ABSOLUTE or mouseButtonToDownFlags(button),
    time: 0.DWORD,
    dwExtraInfo: getMessageExtraInfo())
  inputs[1] = MOUSEINPUT(
    kind: INPUT_MOUSE,
    dx: x,
    dy: y,
    mouseData: 0.DWORD,
    dwFlags: MOUSEEVENTF_ABSOLUTE or mouseButtonToUpFlags(button),
    time: 0.DWORD,
    dwExtraInfo: getMessageExtraInfo())
  let res = sendInput(len(inputs).uint, inputs[0].addr, sizeof(MOUSEINPUT))
  assert res == len(inputs).uint
  m

proc click*(m: MouseCtx, x, y: int32): MouseCtx {.inline, discardable.} =
  result = click(m, mLeft, x, y)

proc move*(m: MouseCtx, x, y: int): MouseCtx {.discardable.} =
  discard setCursorPos(x, y)
  m

proc pos(m: MouseCtx): Point =
  discard getCursorPos(result.addr)

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