{async, isArray} = require "fairmont"
{all} = require "when"

global.p = -> console.error arguments...

module.exports = async (name, args...) ->

  [
    shared
    Commands
    Options
  ] = yield all [
    require "./shared"
    require "./commands"
    require "./options"
  ]


  {bye, error, _error} = shared.loggers.output

  options = Options.parse "main", process.argv

  # shared.dryRun = options.dry_run
  # TODO: use option for this
  shared.dryRun = true

  # TODO: use this to set logging level
  # verbosity = options.verbose.length

  [command, args...] = options._args.sort().reverse()

  if (command = Commands[name])?
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
    bye "bad-command", {name}
