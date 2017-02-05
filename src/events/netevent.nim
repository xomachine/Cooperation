type
  RawMessageRecvd* = object
    sender*: string
    id*: int8
    data*: string
    answer*: proc(data: string)
