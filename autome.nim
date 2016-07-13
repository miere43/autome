## This module contains useful procs that can be used to automate boring GUI
## tasks.
##
## Concept: contexts
## ------------------------
## The ``autome`` namespace contains several variables available for you:
## `mouse<#mouse>`_ and `keyboard<#keyboard>`_. They are called
## ``mouse context`` and ``keyboard context`` correspondingly. To use mouse or
## keyboard procs, you must pass these variables in them or create your
## own context.
##
## .. code-block:: nim
##   move(mouse, 640, 480) # move mouse to 640, 480
##   # .. or ..
##   mouse.move(640, 480)
##
## All of mouse or keyboard procs returns same context they have received,
## so you can ``chain`` procs of same context:
##
## .. code-block:: nim
##   mouse
##     .move(640, 480)
##     .click()
##     .move(123, 321)
##
## There are methods that are not bound to specific context, but accept
## them to not break proc chaining (for example, ``wait`` proc).
##
## Currently context variables are used only for nice chaining syntax and
## do not contain any useful data, but this may change in future, so beware if
## you are smart enough and you are passing ``nil`` for `ctx` argument
## of mouse/keyboard procs (͡° ͜ʖ ͡°).

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
include private.hotkey

when isMainModule:
  assert sizeof(MOUSEINPUT) == 28