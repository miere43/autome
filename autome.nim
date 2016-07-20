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

{.deadCodeElim: on.}

import winlean

type
  KeyboardCtx* = ref object ## represents keyboard context.
  MouseCtx* = ref object ## represents mouse context.
    perActionWaitTime: int32
  Window* = distinct Handle ## represents window handle.
  Point* {.pure, final.} = tuple ## represents point on the screen.
    x: int32
    y: int32
  KeyboardModifier* {.size: sizeof(uint32).} = enum ## represents various
  ## keyboard modifiers.
    modAlt = 0, modControl = 1, modShift = 2, modNoRepeat = 14
  KeyboardModifiers* = set[KeyboardModifier] ## represents set of 
  ## keyboard modifiers that can be combined.
  Hotkey* = distinct int ## represents hotkey registered with
  ## `registerHotkey<#registerHotkey>`_ proc.

proc `==`*(a, b: Window): bool {.borrow.}
  ## proc to enable comparison of two windows.

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

include private.imports
include private.common
include private.window
include private.mouse
include private.keyboard
include private.hotkey

when isMainModule:
  #assert(findWindow("Sublime") != 0.Window)
  #var g = registerHotkey(0x43.uint32, {modAlt, modControl})
  #waitForHotkey(66666.Hotkey)
  #echo "k"
  assert sizeof(MOUSEINPUT) == 28
