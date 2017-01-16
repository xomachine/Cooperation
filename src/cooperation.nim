from controlserver import newControlServer, listen, stop
from dataserver import newDataServer, listen, stop
from events.pipe import EventPipe
from events.systemsignals import ExitApplication
from metaevents import emit
from coro import run

when isMainModule:
  var event_pipe = new(EventPipe)
  var cs = newControlServer(event_pipe, 61111)
  var ds = newDataServer(event_pipe, 61111)
  proc on_controlc() {.noconv.} =
    debugEcho("Control-C captured! Firing ExitApplication event...")
    event_pipe[].emit(ExitApplication())
    #cs.stop()
    #ds.stop()
  setControlCHook(on_controlc)
  cs.listen()
  ds.listen()
  run()
  