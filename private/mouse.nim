type
  MouseButton* = enum ## represents mouse button
    mLeft, mRight, mMiddle
  MouseState* = enum ## represents mouse button click state: pressed or released
    msDown, msUp

proc initMouseInput(x, y: LONG, dwFlags: DWORD,
    mouseData: DWORD = 0.DWORD): MOUSEINPUT {.inline.} =
  MOUSEINPUT(
    kind: INPUT_MOUSE,
    dx: x,
    dy: y,
    mouseData: mouseData,
    dwFlags: dwFlags,
    time: 0.DWORD,
    dwExtraInfo: getMessageExtraInfo())

proc pos*(m: MouseCtx): Point =
  ## returns current position of the cursor.
  discard getCursorPos(result.addr)

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
    {.sideEffect, discardable.} =
  ## emulates mouse press and release event.
  var inputs: array[2, MOUSEINPUT]
  inputs[0] = initMouseInput(x, y,
    MOUSEEVENTF_ABSOLUTE or mouseButtonToDownFlags(button))
  inputs[1] = initMouseInput(x, y,
    MOUSEEVENTF_ABSOLUTE or mouseButtonToUpFlags(button))
  let res = sendInput(len(inputs).uint, inputs[0].addr, sizeof(MOUSEINPUT))
  assert res == len(inputs).uint
  m

proc click*(m: MouseCtx, x, y: int32): MouseCtx {.sideEffect, discardable.} =
  ## emulates mouse press with left mouse button at position `x`, `y`.
  result = click(m, mLeft, x, y)

proc click*(m: MouseCtx): MouseCtx {.sideEffect, discardable.} =
  ## enumates mouse press with left mouse button at current mouse position.
  var (x, y) = m.pos()
  result = click(m, mLeft, x, y)

proc doubleclick*(m: MouseCtx): MouseCtx {.sideEffect, discardable.} =
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
    events: varargs[MouseState]): MouseCtx {.sideEffect, discardable.} =
  ## emits mouse press/release events at current mouse position.
  ##
  ## .. code-block:: nim
  ##   mouse.emit(mLeft, msDown, msDown, msDown, msUp) # emulate tripleclick
  var (x, y) = m.pos()
  var inputsLen = len(events)
  var inputs = cast[array[0..9999, MOUSEINPUT]]
    (alloc(sizeof(MOUSEINPUT) * inputsLen))
  var i = 0
  for event in events:
    inputs[i] = initMouseInput(x, y,
      MOUSEEVENTF_ABSOLUTE or mouseButtonToFlags(button, event)) 
    inc(i)
  let res = sendInput(inputsLen.uint, inputs.addr, sizeof(MOUSEINPUT))
  dealloc(inputs.addr)
  assert res == inputsLen.uint
  m

proc move*(m: MouseCtx, x, y: int): MouseCtx {.sideEffect, discardable.} =
  ## sets mouse position to `x` and `y`.
  discard setCursorPos(x, y)
  m

proc movedelta*(m: MouseCtx, dx, dy: int): MouseCtx {.sideEffect,discardable.} =
  ## moves mouse by `dx` and `dy` pixels. This proc may be useful to interface
  ## with window menu bar items, which are not receiving "hover" event when
  ## using `move proc<#move,MouseCtx,int,int>`_.
  var inputs: array[1, MOUSEINPUT]
  inputs[0] = initMouseInput(dx.DWORD, dy.DWORD, mouseButtonToDownFlags(mLeft))
  let res = sendInput(len(inputs).uint, inputs[0].addr, sizeof(MOUSEINPUT))
  assert res == len(inputs).uint
  m

proc x*(m: MouseCtx): int {.inline.} =
  ## returns mouse `x` position.
  var p: POINT
  discard getCursorPos(p.addr)
  p.x

proc y*(m: MouseCtx): int {.inline.} =
  ## returns mouse `y` position.
  var p: POINT
  discard getCursorPos(p.addr)
  p.y

proc x*(m: MouseCtx, pos: int): MouseCtx {.inline, sideEffect, discardable.} =
  ## sets mouse `x` position.
  discard setCursorPos(pos, m.y)
  m

proc y*(m: MouseCtx, pos: int): MouseCtx {.inline, sideEffect, discardable.} =
  ## sets mouse `y` position.
  discard setCursorPos(m.x, pos)
  m

proc `x=`*(m: MouseCtx, pos: int) {.inline, sideEffect.} =
  ## sets mouse `x` position.
  m.x(pos)

proc `y=`*(m: MouseCtx, pos: int) {.inline, sideEffect.} =
  ## sets mouse `y` position.
  m.y(pos)

proc wait*(m: MouseCtx, ms: int): MouseCtx {.inline, sideEffect, discardable.} =
  ## stops execution for `ms` milliseconds.
  wait(ms)
  m