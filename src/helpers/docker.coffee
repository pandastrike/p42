{run} = require "commands"

DockerHelpers =

  # TODO: the env commands won't actually work correctly
  # since we shell out to run them.
  env: (name) -> run "docker.machine.env" {name}

  swarmEnv: (name) ->
    run "docker.machine.swarm-env" {name}

  login: -> run "docker.login"

  build: ({registry, tag, mixin}) ->
    file = join ".run", mixin, "Dockerfile"
    run "docker.build", {tag: "#{registry}/#{tag}", file}

  push: ({registry, tag}) ->
    run "docker.push", tag: "${registry}/${tag}"

  run: ({name, tag, options}) -> run "docker.run", {name, tag, options}

  inspect: (name) -> run "docker.inspect", {name}

  listContainers: (cluster) -> run "docker.ps", {cluster}

  createInstance: (cluster, options) ->
    run "docker.machine.create", cluster

  createSwarmInstance: (cluster) ->
    run "docker.machine.create-swarm-instance", cluster

    setSecurityGroups cluster, node, [ "default", "docker-machine" ]

  findAvailableName: async (cluster) ->
    taken = yield listSwarmNodes cluster
    counter = 0
    while true
      candidate = sprintf "%s-%2d", cluster.name, counter
      if ! candidate in taken
        return candidate

  listSwarmNodes: ({name}) -> run "docker.machine.ls", {name}

  removeSwarmNodes: async (cluster) ->
    nodes = yield listSwarmNodes cluster
    yield run "docker.stop", {nodes}
    yield run "docker.rm", {nodes}

module.exports = DockerHelpers
