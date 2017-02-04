
from nesm import serializable
from proto import MAX_DATA_SIZE

serializable:
  static:
    type
      ControlMessage* = object
        signature*: array[0..3, char]
        version*: int32
        kind*: int8
        data*: array[MAX_DATA_SIZE, char]
