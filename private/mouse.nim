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
