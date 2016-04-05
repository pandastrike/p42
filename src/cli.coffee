{async} = require "fairmont"
{all} = require "when"

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

  if (command = Commands[name])?
    # Options.parse "cluster-#{name}", argv
    yield command args...
  else
    # usage "bad-command", {name}
