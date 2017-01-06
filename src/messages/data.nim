from nesm import serializable

serializable:
  type
    DataMessage* = object
      signature*: array[0..3, char]
      version*: int32
      kind*: int8
      data*: seq[byte]
