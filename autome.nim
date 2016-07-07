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
  wait 1000
  keyboard
    .send("abcd", 10)
  # const fileMenuX = 24
  # const fileMenuY = 35
  # const exportMenuX = 92
  # const exportMenuY = 237
  # const exportPosterMenuX = 232
  # const exportPosterMenuY = 257
  # const outputFileTextboxX = 768
  # const outputFileTextboxY = 433
  # const exportPosterButtonX = 1075
  # const exportPosterButtonY = 600
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
  #   .emit("1")
  # mouse
  #   .wait(500)
  #   .move(1075, 600)
  #   .wait(500)
  #   .click()
  #   .wait(500)
  #wait(1000)
  when defined(test):
    import private.imports
    assert sizeof(MOUSEINPUT) == 28