# {all} = require "when"
{async, collect, pull} = require "fairmont"

_exports = do async ->

  [
    shared
    Application
    DockerHelpers
    Cluster
  ] = yield collect pull [
    require "../shared"
    require "../application"
    require "../helpers/docker"
    require "../cluster"
  ]

  {info} = shared.loggers.status
  {Mixins} = Application

  build = async ({mixins}) ->
    mixins ?= yield Mixins.list()
    info "build.starting", {mixins}
    application = yield Application.load()
    cluster = yield Cluster.load application.cluster
    yield DockerHelpers.swarmEnv cluster.name
    yield DockerHelpers.login()
    yield Mixins.build {mixins}
    info "build.complete", {mixins}

module.exports = _exports
