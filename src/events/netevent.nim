type
  RawMessageRecvd* = object
    sender*: string
    id*: int8
    data*: seq[byte]
  
  RawMessageToSend* = object
    target*: string
    id*: int8
    data*: seq[byte]
