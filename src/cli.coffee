{async, include, isArray} = require "fairmont"
{all} = require "when"

global.$P = -> console.log arguments...

module.exports = async (args) ->

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

  options = Options.parse args

  include shared.settings, options
  # TODO: get rid of hard-coded override
  shared.settings.dryRun = true

  if (command = Commands[options.command])?
    try
      yield command options
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
    bye "bad-command", name: options.command
