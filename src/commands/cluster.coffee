{all} = require "when"
{async} = require "fairmont"
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

  {bye, info} = shared.loggers.output

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

  async (args...) ->

    _options = Options.parse "cluster.main", args
    [name, args...] = _options._args

    if (command = Commands[name])?
      _options = Options.parse "cluster.#{name}", args
      [name, bad] = _options._args
      if bad?
        bye "bad-option", name: bad
      else
        options = {name}
        for key, value of _options when ! key.match /^_/
          options[key] = value
        p options
        # yield command options
    else
      bye "bad-subcommand", {name}

module.exports = _exports
