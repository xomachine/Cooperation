from coro import suspend, start
from typetraits import name
from metaevents import emit, on_event, detach
from nativesockets import AF_INET, SOCK_DGRAM, IPPROTO_UDP
from nativesockets import setBlocking, select
from net import newSocket, recvFrom, setSockOpt, getFd,
  bindAddr
from net import close, sendTo, IPv4_broadcast, `$`
from net import Socket, Port
from net import OptReuseAddr, OptReusePort, OptBroadcast
from events.pipe import EventPipe
from events.netevent import RawMessageRecvd
from events.system import ExitApplication
from events.internal import CancelTask, TaskCanceled,
                            TaskCompleted
from interfaces.messages.control import size, serialize,
  deserialize
from interfaces.messages.control import ControlMessage,
                                        MessageType
from interfaces.messages.proto import MAX_DATA_SIZE,
  PROTO_VERSION, PROGRAM_SIGNATURE

type
  ControlServer* = ref object
    socket: Socket
    event_stream: ref EventPipe
    port: int32
    alive: bool

proc messageSender[T](self: ControlServer, e: T): bool =
  let msgkind =
    case name(T)
    of "TaskCompleted": MessageType.taskCompleted.uint8
    of "TaskCanceled": MessageType.taskCanceled.uint8
    else: 0
  var message = ControlMessage(signature: PROGRAM_SIGNATURE,
    version: PROTO_VERSION,
    kind: msgkind)
  case name(T)
  of "TaskCompleted", "TaskCanceled":
    message.id = e.id
  else:
    discard
  let msgdata = message.serialize()
  0 < self.socket.sendTo($IPv4_broadcast(), Port(self.port),
                         msgdata)
    
proc stop*(self: ControlServer) =
  self.alive = false

proc newControlServer*(event_stream: ref EventPipe,
                       port: int32): ControlServer =
  new(result)
  result.alive = false
  result.socket = newSocket(AF_INET, SOCK_DGRAM, IPPROTO_UDP, false)
  result.socket.setSockOpt(OptReuseAddr, true)
  result.socket.setSockOpt(OptReusePort, true)
  result.socket.setSockOpt(OptBroadcast, true)
  result.socket.getFd().setBlocking(false)
  # CAUTION: Not sure if data is being lost when socket
  # in both non-blocking and unbuffered
  result.event_stream = event_stream
  result.port = port
  let self = result
  proc tc_send_handler(e: TaskCanceled): bool =
    self.messageSender(e)
  proc tf_send_handler(e: TaskCompleted): bool =
    self.messageSender(e)
  proc stop_handler(e: ExitApplication): bool =
    self.stop()
    self.event_stream[].detach(stop_handler)
    self.event_stream[].detach(tc_send_handler)
    self.event_stream[].detach(tf_send_handler)
  result.event_stream[].on_event(tc_send_handler)
  result.event_stream[].on_event(tf_send_handler)
  result.event_stream[].on_event(stop_handler)
    

proc dispatcher(self: ControlServer, address: string, data: string) =
  let msg = ControlMessage.deserialize(data)
  if msg.signature == PROGRAM_SIGNATURE and msg.version == PROTO_VERSION:
    case msg.kind
    of MessageType.cancelTask.uint8:
      let msg_event = CancelTask(id: msg.id)
      self.event_stream.emit(msg_event)
    else:
      discard

proc listen*(self: ControlServer) =
  self.socket.bindAddr(Port(self.port))
  self.alive = true
  proc listener() =
    var buffer = newString(ControlMessage.size())
    var address = newString(0)
    var port = Port(0)
    debugEcho "UDP cycle is started"
    while self.alive:
      var sockseq = @[self.socket.getFd()]
      if sockseq.select(0) > 0:
        let received = self.socket.recvFrom(buffer, ControlMessage.size(), address, port)
        if received > 0:
          self.dispatcher(address, buffer)
      suspend(1)
    debugEcho "UDP listener is finished"
    self.socket.close()
  start(listener)
