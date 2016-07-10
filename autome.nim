import private.imports, winlean

type
  KeyboardCtx* = ref object
    none: byte
  MouseCtx* = ref object
    none: byte
  WindowRef* = ref object
    handle*: Handle

let
  mouse* = MouseCtx() ## default mouse context. You can use it like that:
  ##
  ## .. code-block:: nim
  ##   mouse
  ##     .move(200, 200)
  ##     .click()
  keyboard* = KeyboardCtx() ## default keyboard context. You can use it like
  ## that:
  ##
  ## .. code-block:: nim
  ##   keyboard
  ##     .send("hello")

include private.common
include private.window
include private.mouse
include private.keyboard

when isMainModule:
  findWindow("Powershell").attach().show().detach()
  when defined(test):
    assert sizeof(MOUSEINPUT) == 28