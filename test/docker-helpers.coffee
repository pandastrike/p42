assert = require "assert"
{async, isArray} = require "fairmont"
{command} = require "./helpers"

module.exports = (context) ->

  context.test "Docker", (context) ->

    DockerHelpers = yield require "../src/helpers/docker"

    command "env", context, ->
      DockerHelpers.env "violent-aftermath-01"

    command "swarmEnv", context, ->
      DockerHelpers.swarmEnv "violent-aftermath"

    command "login", context, ->
      DockerHelpers.login()

    command "build", context, ->
      DockerHelpers.build
        registry: '123456789.registry.test.com'
        tag: 'blurb9-api'
        mixin: 'api'

    command "push", context, ->
      DockerHelpers.push
        registry: '123456789.registry.test.com'
        tag: 'blurb9-api'

    command "run", context, ->
      DockerHelpers.run
        name: "api-00"
        tag: "blurb9-api"
        options: "-P"

    command "inspect", context, async ->
      {name, ip, port} = yield DockerHelpers.inspect "api-00"

      assert name?
      assert ip?
      assert port?

    command "listContainers", context, ->
      DockerHelpers.listContainers "violent-aftermath"


    command "createInstance", context, ->
      DockerHelpers.createInstance
        cluster:
          vpcId: "test-vpc-00"
          subnetId: "test-subnet-00"
          region: "us-west-1"
          zoneId: "test-dns-00"
        name: "violent-aftermath-00"

    command "createSwarmInstance", context, ->
      DockerHelpers.createInstance
        cluster:
          vpcId: "test-vpc-00"
          subnetId: "test-subnet-00"
          region: "us-west-1"
          zoneId: "test-dns-00"
        name: "violent-aftermath-00"

    command "listSwarmNodes", context, async ->
      nodes = yield DockerHelpers.listSwarmNodes "violent-aftermath"
      assert isArray nodes

    command "findAvailableName", context, async ->
      name = yield DockerHelpers.findAvailableName "violent-aftermath"
      assert.equal name, "violent-aftermath-03"

    command "removeSwarmNodes", context, ->
      DockerHelpers.removeSwarmNodes "violent-aftermath"
