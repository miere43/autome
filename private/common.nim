proc sleep*(ms: int): void {.inline, sideEffect.} =
  ## suspends the execution of current thread
  ## until the time-out interval elapses. Time is in milliseconds.
  imports.sleep(ms.DWORD)