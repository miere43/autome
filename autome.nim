import private.imports, winlean

type
  MouseCtx* = ref object
    speed*: int
  WindowRef* = ref object
    handle*: Handle

let
  ## default mouse context
  mouse = MouseCtx()

include private.common
include private.window
include private.mouse
include private.keyboard

when isMainModule:
  wait(1000)
  mouse.emit(mLeft, msDown, msDown, msDown, msUp)
  # var g = findWindow("Notepad")
  # echo repr g
  # echo setForegroundWindow(g.handle)
  #mouse.doubleclick()
  #mouse.click(0, 0)
  #mouse
    #.move(600, 200)
  #echo mouse.pos
  # var p: POINT
  # discard getCursorPos(p.addr)
  # echo setCursorPos(800, 600)
  # discard getCursorPos(p.addr)
  # echo $p
  when defined(test):
    import private.imports
    assert sizeof(MOUSEINPUT) == 28