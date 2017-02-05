from metaevents import declareEventPipe
from netevent import RawMessageRecvd
from events.system import ExitApplication
from internal import TaskCanceled, TaskCompleted, CancelTask

declareEventPipe(EventPipe, RawMessageRecvd,
                            ExitApplication,
                            TaskCanceled,
                            TaskCompleted,
                            CancelTask)
