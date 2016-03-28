{async} = require "fairmont"
Application  = require "../application"
Cluster = require "../cluster"
AWSHelpers = require "../helpers/aws"
DockerHelpers = require "../helpers/dockers"

Commands =

  create: async ->
    name = yield Name.generate()
    cluster = yield AWSHelpers.createCluster name
    AWSHelpers.createSwarmMaster cluster

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

module.exports = (name, argv...) ->
  if (command = Commands[name])?
    # Options.parse "cluster-#{name}", argv
    command argv...
  else
    # usage "bad-subcommand", {name}
