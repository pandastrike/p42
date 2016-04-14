{promise} = require "when"
{spawn} = require "child_process"
{EventEmitter} = require "events"

module.exports = ({stdout, stderr}) ->

  # Run commands from stdin within a single process, using the
  # file separate character (\u001c) to indicate that a command has
  # completed
  p = spawn "bash",
    [
      "-c"
      "while true ; do read -r line; eval $line; printf '\u001c'; done"
    ]

  p.stdout.pipe stdout if stdout?
  p.stderr.pipe stderr if stderr?

  p.on "error", (e) -> console.error e

  events = new EventEmitter()
  do (result = "") ->
    p.stdout.on "data", (buffer) ->
      string = buffer.toString()
      if (match = string.match /\u001c/)?
        {index} = match
        result += string[...index]
        events.emit "result", result
        result = string[(index+1)..]
      else
        result += string

  # Each call to run MUST WAIT on the promise to resolve
  # before the next call can be made. Otherwise, two
  # commands can potentially get the same result event.
  run: (s) ->
    promise (resolve, reject) ->
      p.stdin.write s + "\n"
      events.once "result", resolve

  close: -> p.kill()
