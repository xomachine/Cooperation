
from nesm import serializable
from proto import MAX_DATA_SIZE
from interfaces.task import TaskId

type MessageType* = enum
  taskCompleted = 1'u8
  taskCanceled
  cancelTask

serializable:
  static:
    type
      ControlMessage* = object
        signature*: array[0..3, char]
        version*: int32
        case kind*: uint8
        of taskCompleted.uint8, taskCanceled.uint8,
           cancelTask.uint8:
          id*: TaskId
        else:
          discard
