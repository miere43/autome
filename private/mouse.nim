# included in autome.nim

import macros

macro mouseAction(s: expr): expr =
  ## adds ``execActionWait(mouseCtx)`` and ``mouseCtx`` to the end of the proc.
  ## This results in calling ``execActionWait`` proc and returning
  ## ``mouseCtx`` from proc. This macro should be added to "mouse action" procs
  ## which change mouse state, eg. moving it around the screen.
  expectKind(s, nnkProcDef) # allow only procs

  var formalParams = findChild(s, it.kind == nnkFormalParams)

  var mouseCtxArgName: NimNode = nil

  for identDef in formalParams:
    if identDef.kind != nnkIdentDefs:
      continue
    var argtype = $identDef[1]
    if argtype == "MouseCtx":
      mouseCtxArgName = identDef[0]
      break

  if mouseCtxArgName == nil:
    error("this proc does not contain arg of type MouseCtx.")

  var procBody = findChild(s, it.kind == nnkStmtList)
  if procBody == nil:
    error("this proc has no body")

  procBody.add(newCall("execActionWait", mouseCtxArgName))
  procBody.add(mouseCtxArgName)

  # echo treeRepr(s)
  return s

type
  MouseButton* = enum ## represents mouse button
    mLeft, mRight, mMiddle
  MouseState* = enum ## represents mouse button click state: pressed or released
    msDown, msUp

proc execActionWait(mouse: MouseCtx) =
  ## makes thread to sleep for ``mouse.preActionWaitTime`` if it is more than 0.
  if mouse.perActionWaitTime > 0:
    sleep(mouse.perActionWaitTime)

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

proc setActionWaitTime*(mouse: MouseCtx, ms: int32,
    waitToo: bool = true): MouseCtx {.inline.} =
  ## change action wait time of mouse. This proc specifies for how much 
  ## this application thread should sleep before continuing execution
  ## after each ``MouseCtx`` action like ``move()`` or ``click()``. Change
  ## to ``0`` to disable waiting after each action.
  ## If ``waitToo`` is true, this proc will wait ``ms`` milliseconds before
  ## executing.
  mouse.perActionWaitTime = ms
  if waitToo:
    execActionWait(mouse)
  mouse

proc pos*(m: MouseCtx): Point =
  ## returns current position of the cursor.
  discard getCursorPos(result.addr)

proc click*(m: MouseCtx, button: MouseButton, x, y: int32): MouseCtx
    {.sideEffect, mouseAction, discardable.} =
  ## emulates mouse press and release event.
  var inputs: array[2, MOUSEINPUT]
  inputs[0] = initMouseInput(x, y,
    MOUSEEVENTF_ABSOLUTE or mouseButtonToDownFlags(button))
  inputs[1] = initMouseInput(x, y,
    MOUSEEVENTF_ABSOLUTE or mouseButtonToUpFlags(button))
  let res = sendInput(len(inputs).uint, inputs[0].addr, sizeof(MOUSEINPUT))
  assert res == len(inputs).uint

proc click*(m: MouseCtx, x, y: int32): MouseCtx
    {.sideEffect, mouseAction, discardable.} =
  ## emulates mouse press with left mouse button at position `x`, `y`.
  discard click(m, mLeft, x, y)

proc click*(m: MouseCtx): MouseCtx {.sideEffect, mouseAction, discardable.} =
  ## enumates mouse press with left mouse button at current mouse position.
  var (x, y) = m.pos()
  discard click(m, mLeft, x, y)

proc doubleclick*(m: MouseCtx): MouseCtx
    {.sideEffect, mouseAction, discardable.} =
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

proc emit*(m: MouseCtx, button: MouseButton,
    events: varargs[MouseState]): MouseCtx
    {.sideEffect, mouseAction, discardable.} =
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

proc move*(m: MouseCtx, x, y: int): MouseCtx
    {.sideEffect, mouseAction, discardable.} =
  ## sets mouse position to `x` and `y`.
  discard setCursorPos(x, y)

proc movedelta*(m: MouseCtx, dx, dy: int): MouseCtx
    {.sideEffect, mouseAction, discardable.} =
  ## moves mouse by `dx` and `dy` pixels. This proc may be useful to interface
  ## with window menu bar items, which are not receiving "hover" event when
  ## using `move proc<#move,MouseCtx,int,int>`_.
  var inputs: array[1, MOUSEINPUT]
  inputs[0] = initMouseInput(dx.DWORD, dy.DWORD, mouseButtonToDownFlags(mLeft))
  let res = sendInput(len(inputs).uint, inputs[0].addr, sizeof(MOUSEINPUT))
  assert res == len(inputs).uint

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
  execActionWait(m)

proc `y=`*(m: MouseCtx, pos: int) {.inline, sideEffect.} =
  ## sets mouse `y` position.
  m.y(pos)
  execActionWait(m)

proc wait*(m: MouseCtx, ms: int32): MouseCtx {.inline, sideEffect, discardable.} =
  ## stops execution for `ms` milliseconds.
  wait(ms)
  m