{async, isArray, collect, pull} = require "fairmont"

_exports = do async ->

  [
    shared
    Application
  ] = yield collect pull [
    require "../shared"
    require "../application"
  ]

  {bye, error} = shared.loggers.status

  Commands =

    add: -> Application.Targets.add arguments...

    remove: -> Application.Targets.remove arguments...

    rename: -> Application.Targets.rename arguments...


  async (options) ->

    options.name = options.cluster

    if (command = Commands[options.subcommand])?
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
      bye "bad-subcommand", name: options.subcommand

module.exports = _exports
