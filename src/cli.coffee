{async, isArray} = require "fairmont"
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

  {info, bye} = shared.loggers.output

  if (command = Commands[name])?
    # Options.parse "cluster-#{name}", argv
    try
      yield command args...
    catch error
      if isArray error.info
        bye error.info...
  else
    info "bad-command", {name}
    bye "usage"
