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

  {bye, _bye, error} = shared.loggers.output

  if (command = Commands[name])?
    # Options.parse "cluster-#{name}", argv
    try
      yield command args...
    catch e
      # errors expected by p42
      # have a p42 attribute
      if isArray e.p42
        bye e.p42...
      else
        # otherwise, this is unexpected, just re-throw
        error "unexpected-error"
        throw e
  else
    error "bad-command", {name}
    bye "usage"
