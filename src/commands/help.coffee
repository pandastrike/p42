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

  {bye} = shared.loggers.output

  (name = "main") ->
    try
      Options.help name
    catch
      bye "bad-command", {name}

module.exports = _exports
