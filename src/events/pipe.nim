from metaevents import declareEventPipe
from netevent import RawMessageRecvd, RawMessageToSend
from systemsignals import ExitApplication

declareEventPipe(EventPipe, RawMessageRecvd,
                            RawMessageToSend,
                            ExitApplication)
