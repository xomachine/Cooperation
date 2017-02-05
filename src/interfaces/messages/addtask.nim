from nesm import serializable
from interfaces.task import Task, TaskId



serializable:
  type
    AddTask* = tuple
      task: Task

type
  TaskCompleted* = tuple
    id: TaskId
  TaskCanceled* = tuple
    id: TaskId
  CancelTask* = tuple
    id: TaskId
