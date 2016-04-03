{async} = require "fairmont"

_exports = do async ->

  Application = yield require "../application"

  build = (mixins...) -> Application.Mixins.build mixins...

module.exports = _exports
