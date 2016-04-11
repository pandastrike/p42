# {all} = require "when"
{async, collect, pull} = require "fairmont"

_exports = do async ->

  [
    shared
    Application
  ] = yield collect pull [
    require "../shared"
    require "../application"
  ]

  {info} = shared.loggers.status

  build = async ({mixins}) ->
    info "build.starting", {mixins}
    yield Application.Mixins.build mixins...
    info "build.complete", {mixins}

module.exports = _exports
