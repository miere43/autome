# autome
Simple GUI automation tool.

### Features
* mouse: get/set cursor pos, emit clicks
* keyboard: send characters (ASCII only)
* window: get/set window pos, find, show/hide, activate/deactivate, minimize/maximize/unminimize/unmaximize, focus/unfocus
* hotkeys: run your code when user presses certain keyboard combination.

### Documentation
Docs are not always up-to-date, but still: http://miere.ru/docs/autome/

You can also generate docs yourself with `$ nim doc2 autome`.

### Example

```nim
import autome

var wnd = findWindow("Some app")
wnd
  .attach() # attach this thread to window thread, so we can use show()
  .show() # make sure window is in front of other windows
  .detach() # detach this thread
mouse
  .move(400, 400) # select textbox
  .click()
  # press on text box three times so its text got selected
  .emit(mLeft, msDown, msDown, msDown, msUp)
keyboard
  .send("D:/pic.tga") # replace text
mouse
  .move(600, 600) # click submit button
  .click()
```

### TODO
* wait for hotkey with timeout proc
* close window proc
* make distinct window handle
* upload to nimble
* clean up stuff that was leaved after refactoring
* check out why window.size & window.clientsize procs' report wrong values
* implement ton of stuff I forgot about
