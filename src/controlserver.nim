from coro import suspend, start
from metaevents import emit, on_event, detach
from nativesockets import AF_INET, SOCK_DGRAM, IPPROTO_UDP
from nativesockets import setBlocking, select
from net import newSocket, recvFrom, setSockOpt, getFd,
  bindAddr
from net import close, sendTo
from net import Socket, Port
from net import OptReuseAddr, OptReusePort, OptBroadcast
from events.pipe import EventPipe
from events.netevent import RawMessageRecvd, RawMessageToSend
from events.systemsignals import ExitApplication
from interfaces.messages.control import size, serialize,
  deserialize
from interfaces.messages.control import ControlMessage
from interfaces.messages.proto import MAX_DATA_SIZE,
  PROTO_VERSION, PROGRAM_SIGNATURE


type
  ControlServer* = ref object
    socket: Socket
    event_stream: ref EventPipe
    port: int32
    alive: bool
    detach_handlers: proc()

proc messageSender(self: ControlServer, e: RawMessageToSend):bool =
  let message = ControlMessage(signature: PROGRAM_SIGNATURE,
    version: PROTO_VERSION,
    kind: e.id,
    data: cast[array[MAX_DATA_SIZE, byte]](e.data))
  var msgdata = message.serialize()
  0 < self.socket.sendTo(e.target,
    Port(self.port),
    msgdata[0].addr,
    msgdata.len)
    
proc stop*(self: ControlServer) =
  self.alive = false
  self.detach_handlers()

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
  let send_handler = proc(e: RawMessageToSend): bool =
    self.messageSender(e)
  let stop_handler = proc(e: ExitApplication): bool =
    self.stop()
  result.detach_handlers = proc () =
    self.event_stream[].detach(send_handler)
    self.event_stream[].detach(stop_handler)
  result.event_stream[].on_event(send_handler)
  result.event_stream[].on_event(stop_handler)
    

proc dispatcher(self: ControlServer, address: string, data: string) =
  let msg = ControlMessage.deserialize(data)
  if msg.signature == PROGRAM_SIGNATURE and msg.version == PROTO_VERSION:
    let msg_event = RawMessageRecvd(sender: address,
      id: msg.kind,
      data: @(msg.data))
    self.event_stream.emit(msg_event)

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
