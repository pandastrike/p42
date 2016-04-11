{all} = require "when"
{async} = require "fairmont"

_exports = do async ->

  [
    shared
    Application
  ] = yield all [
    require "../shared"
    require "../application"
  ]

  {info} = shared.loggers.output

  build = async ({mixins}) ->
    info "build.starting", {mixins}
    yield Application.Mixins.build mixins...
    info "build.complete", {mixins}

module.exports = _exports
