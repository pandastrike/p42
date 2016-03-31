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

    expand: (name, count=1) ->
      for i in [1..count]
        AWSHelpers.createSwarmInstance yield Cluster.resolve name

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
