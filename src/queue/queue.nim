
from interfaces.task import TaskId, `==`, Task, newTask
type
  QueueEmptyException = object of Exception
  NotInQueueException = object of Exception
  QueueElement = ref object
    task: Task
    next: QueueElement
  Queue* = object
    length: Natural
    head, tail: QueueElement
    


proc append*(self: var Queue, e: Task) =
  var new_element = new(QueueElement)
  new_element.task = e
  if isNil(self.tail):
    self.head = new_element
  else:
    self.tail.next = new_element
  self.length += 1
  self.tail = new_element

proc pop*(self: var Queue): Task =
  let popped = self.head
  if self.length == 0 or isNil(popped):
    raise newException(QueueEmptyException, "The queue is empty!")
  self.head = popped.next
  self.length -= 1
  popped.task

proc remove*(self: var Queue, id: TaskId) =
  var cur: QueueElement = nil
  var to_next = self.head.addr
  while not to_next[].isNil:
    if to_next[].task.id == id:
      to_next[] = to_next[].next
      if to_next[] == self.tail:
        self.tail = cur
      self.length -= 1
      return
    cur = to_next[]
    to_next = cur.next.addr
  raise newException(NotInQueueException,
                     "There is no such Task in queue")

when isMainModule:
  var tasks = newSeq[Task](3)
  tasks[0] = newTask()
  tasks[1] = newTask()
  tasks[2] = newTask()
  var queue = Queue()
  queue.append(tasks[0])
  queue.append(tasks[1])
  var got_it = false
  try:
    queue.remove(tasks[2].id)
  except NotInQueueException:
    got_it = true
  assert(got_it)  
  let first = queue.pop()
  assert(first.id == tasks[0].id)
  queue.remove(tasks[1].id)
  got_it = false
  try:
    queue.remove(tasks[1].id)
  except NotInQueueException:
    got_it = true
  assert(got_it)
  got_it = false
  try:
    let poped = queue.pop()
  except QueueEmptyException:
    got_it = true
  assert(got_it)
