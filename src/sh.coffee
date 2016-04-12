{promise} = require "when"
{spawn} = require "child_process"

module.exports = (stdout, stderr) ->

  # Run commands from stdin within a single subprocess, using the
  # file separate character (\u001c) to indicate that a command has
  # completed
  p = spawn "bash",
    [
      "-c"
      "while true ; do read -r line; eval $line; printf '\u001c'; done"
    ]

  # p.stdout.pipe process.stdout
  # p.stderr.pipe process.stderr

  p.on "error", (e) -> console.error e

  run: (s) ->
    promise (resolve, reject) ->
      p.stdin.write s + "\n"
      results = ""
      listener = (d) ->
        s = d.toString()
        if (match = s.match /\u001c/)?
          p.stdout.removeListener "data", listener
          {index} = match
          s = s[...index] + s[(index+1)..]
          results += s
          resolve results
        else
          results += s

      p.stdout.on "data", listener

  close: -> p.kill()
