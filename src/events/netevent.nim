type
  RawMessageRecvd* = object
    sender*: string
    id*: int8
    data*: string
  
  RawMessageToSend* = object
    target*: string
    id*: int8
    data*: string
