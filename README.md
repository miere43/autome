# autome
Simple GUI automation tool.

```nim
import autome

wait(1500)

var wnd = findWindow("Some app")
wnd.bringToFront()

mouse
  # select textbox
  .move(400, 400)
  .click()
  # press on text box three times so its text got selected
  .emit(mLeft, msDown, msDown, msDown, msUp)
keyboard
  # replace text
  .send("D:/pic.tga")
mouse
  # click submit button
  .move(600, 600)
  .click()
```