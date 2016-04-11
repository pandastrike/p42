{async} = require "fairmont"
{all} = require "when"

_exports = do async ->

  [
    shared
    Options
  ] = yield all [
    require "../shared"
    require "../options"
  ]

  {bye, _error} = shared.loggers.output

  ({name}) ->
    _error Options.help name
    # try
    #   _error Options.help name
    # catch
    #   bye "bad-command", {name}

module.exports = _exports
