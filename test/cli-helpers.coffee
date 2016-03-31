assert = require "assert"
{async, isArray} = require "fairmont"
{command} = require "./helpers"

module.exports = (context) ->

  context.test "CLI", (context) ->

    Cluster = yield require "../src/commands/cluster"
    DockerHelpers = yield require "../src/helpers/docker"

    command "cluster-create", context, ->
      Cluster.create()

    command "cluster-expand", context, ->
      Cluster.expand cluster: "violent-aftermath", count: 3
