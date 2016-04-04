{all} = require "when"
{async} = require "fairmont"
Application  = require "../application"
logger = require "../message-logger"
{yaml} = require "../serialize"

_exports = do async ->

  [
    Cluster
    AWSHelpers
    DockerHelpers
    Name
  ] = yield all [
    require "../cluster"
    require "../helpers/aws"
    require "../helpers/docker"
    require "../name"
  ]

  {bye, msg} = yield logger "output"

  Commands =

    create: async ->
      name = yield Name.generate()
      msg "cluster.create.begin", {name}
      cluster = yield Cluster.create name
      DockerHelpers.createSwarmInstance {cluster, name, master: true}

    expand: async ({name, count}) ->
      names = yield DockerHelpers.findAvailableNames name, count
      cluster = yield Cluster.resolve name
      # TODO: ideally we'd launch all three swarm instances in parallel
      # but that messes up the tests at the moment
      for name in names
        yield DockerHelpers.createSwarmInstance
          name: name
          cluster: cluster

    contract: (cluster, count=1) ->
      bye "not-implemented"

    rm: async (name) ->
      # cluster = yield Cluster.resolve name
      yield DockerHelpers.removeSwarmNodes name
      Cluster.remove name

    ls: -> Cluster.list()

    ps: (name) -> DockerHelpers.listSwarmNodes name

    env: (name) -> DockerHelpers.swarmEnv name

    get: async (name, property) ->
      cluster = yield Cluster.resolve name
      if property? then cluster[property] else yaml cluster

  async (name, args...) ->
    if (command = Commands[name])?
      yield command args...
    else
      # usage

module.exports = _exports
