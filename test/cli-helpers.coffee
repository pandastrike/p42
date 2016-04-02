assert = require "assert"
{all} = require "when"
{async, isArray, chdir} = require "fairmont"
{command} = require "./helpers"

module.exports = (context) ->

  context.test "CLI", (context) ->


    [shared, Cluster, start] = yield all [
      require "../src/shared"
      require "../src/commands/cluster"
      require "../src/commands/start"
    ]

    command "cluster-create", context, ->
      Cluster.create()

    command "cluster-expand", context, ->
      Cluster.expand cluster: "violent-aftermath", count: 3

    command "start", context, ->
      chdir shared.test.app.root
      start()
