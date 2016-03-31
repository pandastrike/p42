{all} = require "when"
{async} = require "fairmont"
Application  = require "../application"

_exports = do async ->

  [Cluster, AWSHelpers, DockerHelpers, Name] =
    yield all [
      require "../cluster"
      require "../helpers/aws"
      require "../helpers/docker"
      require "../name"
    ]

  Commands =

    create: async ->
      name = yield Name.generate()
      cluster = yield Cluster.create name
      DockerHelpers.createSwarmInstance {cluster, name, master: true}

    expand: async ({cluster, count}) ->
      names = yield DockerHelpers.findAvailableNames cluster, count
      cluster = yield Cluster.resolve cluster
      # TODO: ideally we'd launch all three swarm instances in parallel
      # but that messes up the tests at the moment
      for name in names
        yield DockerHelpers.createSwarmInstance
          name: name
          cluster: cluster

    contract: (cluster, count=1) ->
      bye "not-implemented"

    rm: (name) ->
      cluster = yield Cluster.resolve name
      yield AWSHelpers.removeSwarmNodes cluster
      Cluster.remove cluster

    ls: -> Cluster.list()

    ps: (name) ->
      DockerHelper.listSwarmNodes yield Cluster.resolve name

    env: async (name) ->
      DockerHelper.swarmEnv yield Cluster.resolve name

    get: (name, property) ->
      (yield Cluster.resolve name)[property]

module.exports = _exports
