{all} = require "when"
{async, include, isArray} = require "fairmont"
Application  = require "../application"
{yaml} = require "../serialize"

_exports = do async ->

  [
    shared
    Options
    Cluster
    AWSHelpers
    DockerHelpers
    Name
  ] = yield all [
    require "../shared"
    require "../options"
    require "../cluster"
    require "../helpers/aws"
    require "../helpers/docker"
    require "../name"
  ]

  {bye, info, error} = shared.loggers.output

  Commands =

    create: async ->
      name = yield Name.generate()
      info "cluster.create.starting", {name}
      cluster = yield Cluster.create name
      yield DockerHelpers.createSwarmInstance {cluster, name, master: true}
      info "cluster.create.complete", {name}

    expand: async ({name, count}) ->
      names = yield DockerHelpers.findAvailableNames name, count
      cluster = yield Cluster.resolve name
      # TODO: ideally we'd launch all three swarm instances in parallel
      # but that messes up the tests at the moment
      for name in names
        yield DockerHelpers.createSwarmInstance
          name: name
          cluster: cluster

    contract: ({name, count}) ->
      bye "not-implemented"

    rm: async ({name}) ->
      # cluster = yield Cluster.resolve name
      yield DockerHelpers.removeSwarmNodes name
      Cluster.remove name

    ls: -> Cluster.list()

    ps: ({name}) -> DockerHelpers.listSwarmNodes name

    env: ({name}) -> DockerHelpers.swarmEnv name

    get: async ({name, property}) ->
      cluster = yield Cluster.resolve name
      if property? then cluster[property] else yaml cluster

  async (options) ->

    options.name = options.cluster

    if (command = Commands[options.subcommand])?
      try
        yield command options
      catch e
        # errors expected by p42
        # have a p42 attribute
        if isArray e.p42
          bye e.p42...
        else
          # otherwise, this is unexpected, just re-throw
          error "unexpected-error"
          throw e
    else
      bye "bad-subcommand", name: options.subcommand


module.exports = _exports
