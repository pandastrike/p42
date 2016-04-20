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
  {Mixins} = Application

  build = async ({mixins}) ->
    mixins ?= yield Mixins.list()
    info "build.starting", {mixins}
    yield Mixins.build {mixins}
    info "build.complete", {mixins}

module.exports = _exports
