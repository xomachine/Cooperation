from oids import genOid
from nesm import serializable
serializable:
  type
    TaskId* = tuple
      time: int32
      fuzz: int32
      count: int32

    Task* = tuple
      id: TaskId
      cores: int8
      memory: int32
      handler: string
      inputfile: string
      files: seq[string]

proc `==`*(a: TaskId, b:TaskId): bool =
  a.time == b.time and a.fuzz == b.fuzz and a.count == b.count

proc newTaskId*(): TaskId =
  var newoid = genOid()
  assert(newoid.sizeof == result.sizeof)
  copyMem(result.addr, newoid.addr, newoid.sizeof)

proc newTask*(cores: int8 = 0, memory: int32 = 0,
             handler: string = "", inputfile: string = "",
             files: seq[string] = @[]): Task =
  result.id = newTaskId()
  result.cores = cores
  result.memory = memory
  result.handler = handler
  result.files = files
  
