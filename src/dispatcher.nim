from tables import Table
from tables import initTable, contains, `[]`, `[]=`
from os import walkFiles, `/`, getFileInfo
from os import FilePermission
from coro import start, suspend, wait
from streams import newStringStream
from interfaces.task import Task
from interfaces.messages.data import MessageKind
from interfaces.messages.addtask import AddTask, TaskAdded
from interfaces.messages.addtask import deserialize, serialize
from interfaces.queue import Queue, append
from events.pipe import EventPipe
from events.netevent import RawMessageRecvd
from events.system import ExitApplication
from metaevents import on_event, detach
from modules.module import Module
from modules.module import prepare, init

type
  ModulesHandler* = object
    modules: Table[string, Module]
    queue: ref Queue
    initialized: bool

proc addTask(self: ModulesHandler, e: RawMessageRecvd): bool =
  if e.id != MessageKind.addtask.int8:
    return false
  let stream = newStringStream(e.data)
  let message = AddTask.deserialize(stream)
  let task = message.task
  if task.handler in self.modules:
    let prepared = self.modules[task.handler].prepare(task)
    self.queue[].append(prepared)
    let responce = TaskAdded(id: task.id).serialize()
    e.answer(responce)
    # Emit an event or directly add task to the queue

proc initModules*(ep: ref EventPipe, queue: ref Queue,
                  modules_path: string): ModulesHandler =
  var mh: ModulesHandler
  mh.queue = queue
  mh.modules = initTable[string, Module]()
  mh.initialized = false
  proc addTaskHandler(e: RawMessageRecvd): bool =
    while not mh.initialized:
      suspend(0.1)
    mh.addTask(e)
  proc onExit(e: ExitApplication): bool =
    ep[].detach(addTaskHandler)
    ep[].detach(onExit)
  ep[].on_event(addTaskHandler)
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

