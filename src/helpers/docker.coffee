{join} = require "path"
{async} = require "fairmont"
sprintf = require "sprintf"

_exports = do async ->

  shared = yield require "../shared"
  Cluster = yield require "../cluster"
  run = yield require "../run"
  AWSHelpers = yield require "../helpers/aws"

  H =

    # TODO: env, swarmEnv, and login need to be run alongside ensuing commands
    # Solution: create a process that to which we  can pipe arbitrary bash
    # commands, using something like:
    #
    #     while true ; do read -r line; eval $line; done
    #

    env: (name) -> run "docker.machine.env", {name}

    # TODO: dynamically determine the Swarm master
    swarmEnv: (name) ->
      run "docker.machine.swarm.env", name: "#{name}-00"

    login: -> run "docker.login"

    build: ({registry, tag, mixin}) ->
      file = join mixin.path, "Dockerfile"
      run "docker.build", {tag: "#{registry}/#{tag}", file}

    push: ({registry, tag}) ->
      run "docker.push", tag: "#{registry}/#{tag}"

    pull: ({registry, tag}) ->
      run "docker.pull", tag: "#{registry}/#{tag}"

    run: ({name, tag, options}) -> run "docker.run", {name, tag, options}

    inspect: (name) -> run "docker.inspect", {name}

    listContainers: (cluster) -> run "docker.ps", {cluster}

    stopContainers: (name) -> run "docker.stop", {name} 

    # TODO: make "instance" consistent with "node"
    createInstance: ({name, cluster}) ->
      {region, vpcId, subnetId, zoneId} = cluster
      run "docker.machine.create",
        {name, region, vpcId, subnetId, zoneId}

    createSwarmInstance: ({name, cluster, master}) ->
      master ?= false
      {region, vpcId, subnetId, zoneId} = cluster
      run "docker.machine.swarm.create",
        {name, region, vpcId, subnetId, zoneId, master}
      AWSHelpers.setSecurityGroups
        vpcId: vpcId
        instance: name
        groups: [ "default", "docker-machine" ]

    findAvailableNames: async (cluster, count = 1) ->
      taken = yield H.listSwarmNodes cluster
      counter = 0
      names = []
      while names.length < count
        candidate = sprintf "%s-%02d", cluster, counter++
        names.push candidate if ! (candidate in taken)
      names

    listSwarmNodes: (name) -> run "docker.machine.ls", {name}

    removeSwarmNodes: async (cluster) ->
      nodes = yield H.listSwarmNodes cluster
      yield run "docker.machine.stop", {nodes}
      yield run "docker.machine.rm", {nodes}

module.exports = _exports
