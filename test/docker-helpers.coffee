assert = require "assert"
{join} = require "path"
{async, isArray} = require "fairmont"
{command} = require "./helpers"

module.exports = (context) ->

  context.test "Docker", (context) ->

    shared = yield require "../src/shared"
    DockerHelpers = yield require "../src/helpers/docker"

    command "Docker.env", context, ->
      DockerHelpers.env "violent-aftermath-01"

    command "Docker.swarmEnv", context, ->
      DockerHelpers.swarmEnv "violent-aftermath"

    command "Docker.login", context, ->
      DockerHelpers.login()

    command "Docker.build", context, ->
      DockerHelpers.build
        registry: '123456789.registry.test.com'
        tag: 'blurb9-api'
        mixin:
          name: 'api'
          path: join shared.run, "api"

    command "Docker.push", context, ->
      DockerHelpers.push
        registry: '123456789.registry.test.com'
        tag: 'blurb9-api'

    command "Docker.run", context, ->
      DockerHelpers.run
        name: "api-00"
        tag: "blurb9-api"
        options: "-P"

    command "Docker.inspect", context, async ->
      {name, ip, port} = yield DockerHelpers.inspect "api-00"

      assert name?
      assert ip?
      assert port?

    command "Docker.listContainers", context, ->
      DockerHelpers.listContainers "violent-aftermath"


    command "Docker.createInstance", context, ->
      DockerHelpers.createInstance
        cluster:
          vpcId: "test-vpc-00"
          subnetId: "test-subnet-00"
          region: "us-west-1"
          zone: "a"
        name: "violent-aftermath-00"

    command "Docker.createSwarmInstance", context, ->
      DockerHelpers.createSwarmInstance
        cluster:
          vpcId: "test-vpc-00"
          subnetId: "test-subnet-00"
          region: "us-west-1"
          zone: "a"
        name: "violent-aftermath-00"

    command "Docker.listSwarmNodes", context, async ->
      nodes = yield DockerHelpers.listSwarmNodes "violent-aftermath"
      assert isArray nodes

    command "Docker.findAvailableNames", context, async ->
      [name] = yield DockerHelpers.findAvailableNames "violent-aftermath", 1
      assert.equal name, "violent-aftermath-03"

    command "Docker.removeSwarmNodes", context, ->
      DockerHelpers.removeSwarmNodes "violent-aftermath"
