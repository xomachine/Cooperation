from interfaces.task import TaskId
type
  TaskCanceled* = object
    id*: TaskId
  TaskCompleted* = object
    id*: TaskId
  CancelTask* = object
    id*: TaskId


