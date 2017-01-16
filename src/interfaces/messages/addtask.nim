from nesm import serializable
from interfaces.task import Task



serializable:
  type
    AddTask* = object
      task*: Task
  
  
