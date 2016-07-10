# autome
Simple GUI automation tool.

```nim
import autome

var wnd = findWindow("Some app")
wnd
  .attach() # attach this thread to window thread
  .show() # bring window to front
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
wnd
  .detach() # detach this thread from window thread
```