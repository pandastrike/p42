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

  {bye, info, error} = shared.loggers.status

  Commands =

    create: async ->
      name = yield Name.generate()
      info "cluster.create.starting", {name}
      cluster = yield Cluster.create name
      yield DockerHelpers.createSwarmInstance {cluster, name, master: true}
      info "cluster.create.complete", {name}

    expand: async ({name, count}) ->
      {name} = cluster = yield Cluster.resolve name
      info "cluster.expand.starting", {name, count}
      names = yield DockerHelpers.findAvailableNames name, count
      # TODO: ideally we'd launch all three swarm instances in parallel
      # but that messes up the tests at the moment
      for _name in names
        yield DockerHelpers.createSwarmInstance
          name: _name
          cluster: cluster
      info "cluster.expand.complete", {name, count}

    contract: ({name, count}) ->
      bye "not-implemented"

    rm: async ({name}) ->
      {name} = yield Cluster.resolve name
      info "cluster.rm.starting", {name}
      yield DockerHelpers.removeSwarmNodes name
      yield Cluster.remove name
      info "cluster.rm.complete", {name}

    ls: -> Cluster.list()

    ps: async ({name}) ->
      {name} = yield Cluster.resolve name
      DockerHelpers.listSwarmNodes name

    env: async ({name}) ->
      {name} = yield Cluster.resolve name
      DockerHelpers.swarmEnv name

    get: async ({name, property}) ->
      cluster = yield Cluster.resolve name
      if property? then cluster[property] else cluster

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
