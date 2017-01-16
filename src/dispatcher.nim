from tables import Table
from tables import initTable, contains, `[]`, `[]=`
from os import walkFiles, `/`, getFileInfo
from os import FilePermission
from coro import start, suspend, wait
from interfaces.task import Task
from interfaces.messages.data import MessageKind
from interfaces.messages.addtask import AddTask
from interfaces.messages.addtask import deserialize
from events.pipe import EventPipe
from events.netevent import RawMessageRecvd
from metaevents import on_event, detach
from modules.module import Module
from modules.module import prepare, init

type
  ModulesHandler* = object
    modules: Table[string, Module]
    on_destroy: proc()
    initialized: bool

proc closeModules*(self: ModulesHandler) =
  self.on_destroy()

proc initModules*(ep: ref EventPipe,
                 modules_path: string): ModulesHandler =
  var mh: ModulesHandler
  mh.modules = initTable[string, Module]()
  mh.initialized = false
  let addTaskHandler = proc(e: RawMessageRecvd): bool =
    while not mh.initialized:
      suspend(0.1)
    if e.id != MessageKind.addtask.int8:
      return false
    var index = 0
    let feeder = proc (count: Natural): seq[byte] =
      result = e.data[index..index+count]
      index += count
    let message = AddTask.deserialize(feeder)
    let task = message.task
    if task.handler in mh.modules:
      let prepared = mh.modules[task.handler].prepare(task)
  ep[].on_event(addTaskHandler)
  mh.on_destroy = proc () =
    ep[].detach(addTaskHandler)
  var initializers = newSeq[proc()]()
  for file in walkFiles(modules_path):
    let info = file.getFileInfo()
    if FilePermission.fpUserExec in info.permissions:
      let init_module = proc () =
        try:
          let new_module = init(file)
          mh.modules[new_module.name] = new_module
        except:
          return
      initializers.add(init_module)
      start(init_module)
  let finisher = proc() =
    for initializer in initializers:
      initializer.wait(0.1)
    mh.initialized = true
  start(finisher)
  mh

