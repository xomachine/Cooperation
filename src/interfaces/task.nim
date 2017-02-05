from oids import genOid, Oid
from nesm import serializable
serializable:
  static:
    type TaskId* = tuple
      time: int32
      fuzz: int32
      count: int32

  type Task* = tuple
    id: TaskId
    cores: int8
    memory: int32
    handler: string
    inputfile: string
    files: seq[string]


proc `$`*(s: TaskId): string =
  $(cast[Oid](s))

proc newTaskId*(): TaskId =
  cast[TaskId](genOid())

proc newTask*(cores: int8 = 0, memory: int32 = 0,
             handler: string = "", inputfile: string = "",
             files: seq[string] = @[]): Task =
  result.id = newTaskId()
  result.cores = cores
  result.memory = memory
  result.handler = handler
  result.files = files
  
