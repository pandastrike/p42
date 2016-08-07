{async, include, isObject, isString, isArray, isDefined, isUndefined, isPromise, Method} = require "fairmont"
{all} = require "when"
{yaml} = require "./serialize"

global.$P = -> console.log arguments...
$P.p = (x = "hola")-> $P "----> #{x} <-----"

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

  {bye, error, _error} = shared.loggers.status
  O = shared.loggers.output

  show = Method.create()

  Method.define show, isUndefined, ->
  Method.define show, isDefined, (x) -> show x.toString()
  Method.define show, isPromise, (p) -> p.then (x) -> show x
  Method.define show, isString, (s) -> O.info s
  Method.define show, isArray, (ax) -> show a for a in ax ;;
  # could support JSON flag here
  Method.define show, isObject, (o) -> show yaml o


  try

    options = Options.parse args

    include shared.settings, options

    if shared.settings.dryRun
      shared.loggers.command._self.loggers.stderr.level = "debug"

    if shared.settings.verbose
      shared.loggers.status._self.loggers.stderr.level = "debug"

    if (command = Commands[options.command])?
      show yield command options
    else
      bye "bad-command", name: options.command

  catch e
    # errors expected by p42
    # have a p42 attribute
    if isArray e.p42
      bye e.p42...
    else
      # otherwise, this is unexpected, just re-throw
      error "unexpected-error", e
      _error e.stack
      throw e

  finally

    # be sure to shut down the shell process
    if !shared.settings.dryRun
      process.exit 0
