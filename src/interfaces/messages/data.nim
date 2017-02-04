from nesm import serializable

type
  MessageKind* {.pure.} = enum
    addtask = (1'i8, "AddTaskMessage")
    
serializable:
  type
    DataMessage* = object
      signature*: array[0..3, char]
      version*: int32
      kind*: int8
      data*: string
