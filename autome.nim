import private.imports, winlean

type
  KeyboardCtx* = ref object
    none: byte
  MouseCtx* = ref object
    none: byte
  WindowRef* = ref object
    handle*: Handle

let
  ## default mouse context
  mouse = MouseCtx()
  ## default keyboard context
  keyboard = KeyboardCtx()

include private.common
include private.window
include private.mouse
include private.keyboard

when isMainModule:
  #wait 1000
  #echo eW()
  # var wp = WINDOWPLACEMENT()
  # wp.length = sizeof(WINDOWPLACEMENT).uint32
  # echo getWindowPlacement(wnd, wp.addr)
  # echo "flags: ", wp.flags
  # echo "showcmd: ", wp.showCmd
  # echo "minimized: ", wnd.minimized
  # echo "maximized: ", wnd.maximized
  # wnd.show()
  var wnd = findWindow("azzaza")
  echo wnd.size()
  echo wnd.clientsize()
  #findWindow("Steam").resize(123, 321).move(500, 500)
  #echo "err ", getLastError()
  #echo newWinString(str)
  #var h = findWindow("Notepad", nil)#WindowRef(handle: 0x002f0b84)
  #echo repr h
  # wait 2500
  # mouse
  #   .move(24, 35)
  #   .wait(500)
  #   .click()
  #   .wait(500)
  #   .wait(500)
  #   .move(92, 237)
  #   .movedelta(0, 1)
  #   .wait(500)
  #   .move(232, 257)
  #   .wait(500)
  #   .click()
  #   .wait(500)
  #   .move(768, 433)
  #   .wait(500)
  #   .emit(mLeft, msDown, msDown, msDown, msUp)
  #   .wait(500)
  # keyboard
  #   .send("D:/image.tga", 1234)
  # mouse
  #   .wait(500)
  #   .move(1075, 600)
  #   .wait(500)
  #   .click()
  #   .wait(500)
  # wait(1000)
  when defined(test):
    import private.imports
    assert sizeof(MOUSEINPUT) == 28