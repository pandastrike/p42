{async} = require "fairmont"
{all} = require "when"
logger = require "./message-logger"

global.p = -> console.error arguments...

module.exports = async (name, args...) ->

  [
    shared
    Commands
  ] = yield all [
    require "./shared"
    require "./commands"
  ]

  # TODO: set this as an option
  shared.dryRun = true

  {log} = yield logger "output"
  log.pipe process.stdout

  if (command = Commands[name])?
    # Options.parse "cluster-#{name}", argv
    yield command args...
  else
    # usage "bad-command", {name}
