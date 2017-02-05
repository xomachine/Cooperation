from osproc import Process
from osproc import startProcess, running, outputStream, close,
                   inputStream, hasData, peekExitCode
from jser import toJson, fromJson
from json import `$`, parseJson
from interfaces.task import Task
from coro import suspend
from streams import write

type
  Module* = object
    name*: string
    filepath: string
  
  ModuleFailed = object of Exception
  
  NameData = tuple
    name: string

proc cooperativeWait(p: Process, time: Natural) =
  ## Waits for a time or the Process end with releasing
  ## workflow for other coroutines
  var timer = time
  while p.running() and timer > 0:
    suspend(0.1)
    timer -= 1
  
proc init*(filepath: string): Module =
  ## Checks if filepath is an external module by requesting
  ## its name.
  var process = startProcess(filepath, args = ["-n"])
  # When timer is 0 - process should be forced to be killed
  let output = process.outputStream()
  process.cooperativeWait(10)
  if process.hasData() and process.peekExitCode() == 0:
    let jsondata = parseJson(output, "")
    var namedata: NameData
    namedata.fromJson(jsondata)
    result.name = namedata.name
    result.filepath = filepath
  else:
    raise newException(ModuleFailed,
                       "Module process returned exitcode " &
                       $process.peekExitCode() &
                       ", or returned no data")
  process.close()

proc prepare*(self: Module, task: Task): Task =
  ## Prepares *Task* before addition to queue via
  ## external module
  let serialized = $task.toJson()
  var process = startProcess(self.filepath, args = ["-p"])
  let input = process.inputStream()
  let output = process.outputStream()
  input.write(serialized)
  # Should be data write
  process.cooperativeWait(10)
  if process.hasData() and process.peekExitCode() == 0:
    let jsondata = parseJson(output, "")
    result.fromJson(jsondata)
  else:
    process.close()
    raise newException(ModuleFailed,
                       "Module process returned exitcode " &
                       $process.peekExitCode() &
                       ", or returned no data")
  process.close()
 