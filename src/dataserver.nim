from interfaces.messages.data import DataMessage
from interfaces.messages.data import serialize, deserialize
from interfaces.messages.proto import PROGRAM_SIGNATURE,
  PROTO_VERSION
from events.pipe import EventPipe
from events.netevent import RawMessageRecvd
from events.system import ExitApplication
from metaevents import emit, detach, on_event
from utils.socketstream import newSocketStream
from net import newSocket, getFd, bindAddr, listen, accept, close
from net import setSockOpt, getPeerAddr, recv
from net import Socket, Port
from net import OptReuseAddr, OptReusePort
from nativesockets import setBlocking, select
from coro import suspend, start

type
  DataServer* = ref object
    socket: Socket
    event_pipe: ref EventPipe
    port: int32
    alive: bool

proc stop*(self: DataServer) =
  self.alive = false
  debugEcho "Shutting down data server"

proc newDataServer*(pipe: ref EventPipe, port: int32): DataServer =
  new(result)
  result.alive = false
  result.socket = newSocket(buffered = false)
  result.event_pipe = pipe
  result.port = port
  result.socket.getFd().setBlocking(false)
  result.socket.setSockOpt(OptReuseAddr, true)
  result.socket.setSockOpt(OptReusePort, true)
  let self = result
  proc stop_handler(e: ExitApplication): bool =
    self.stop()
    self.event_pipe[].detach(stop_handler)
  result.event_pipe[].on_event(stop_handler)

proc handle_client(self: DataServer, client: Socket) =
  var socketStream = newSocketStream(client)
  let message = try: DataMessage.deserialize(socketStream)
    except OSError: DataMessage()
  if message.signature != PROGRAM_SIGNATURE or
     message.version != PROTO_VERSION:
    return
  let address = client.getPeerAddr()[0]
  let event = RawMessageRecvd(sender: address,
                              id: message.kind,
                              data: message.data)
  self.event_pipe[].emit(event)
  client.close()

proc listen*(self: DataServer) =
  self.socket.bindAddr(Port(self.port))
  proc listener() =
    self.alive = true
    var client: Socket = newSocket(buffered = false)
    self.socket.listen()
    debugEcho "Cycle is started"
    while self.alive:
      var sockseq = @[self.socket.getFd()]
      if sockseq.select(0) > 0:
        self.socket.accept(client)
        proc handle() =
          self.handle_client(client)
        start(handle)
        client = newSocket(buffered = false)
      suspend(1)
    self.socket.close()
    debugEcho "TCP listener finished"
  start(listener)
