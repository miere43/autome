proc valid*(w: WindowRef): bool =
  w.handle != 0

proc findWindow*(title: string, class: string = nil): WindowRef =
  var handle = imports.findWindow(newWinString(title),
    newWinString(class))
  WindowRef(handle: handle)

proc bringToFront*(w: WindowRef): bool =
  imports.setForegroundWindow(w.handle).bool