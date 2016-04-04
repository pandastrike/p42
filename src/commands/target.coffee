{async} = require "fairmont"

_exports = do async ->

  Application = yield require "../application"

  Commands =

    add: -> Application.Targets.add arguments...

    remove: -> Application.Targets.remove arguments...

    rename: -> Application.Targets.rename arguments...

module.exports = _exports
