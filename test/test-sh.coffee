{async} = require "fairmont"

createShell = require "../src/sh"
shell = createShell process.stdout, process.stderr

readline = require "readline"
rl = readline.createInterface process.stdin, process.stdout
rl.setPrompt = "> "
rl.prompt()
rl.on "line", async (line) ->
  result = yield shell.run line
  process.stdout.write result
  rl.prompt()
rl.on "close", ->
  shell.close()
  process.exit 0
