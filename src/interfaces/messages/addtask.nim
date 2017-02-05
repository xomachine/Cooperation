from nesm import serializable
from interfaces.task import Task, TaskId



serializable:
  type
    AddTask* = tuple
      task: Task
