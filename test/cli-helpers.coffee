assert = require "assert"
{all} = require "when"
{async, isArray, chdir} = require "fairmont"
{command} = require "./helpers"

module.exports = (context) ->

  context.test "CLI", (context) ->

    [shared, Cluster, start, build] = yield all [
      require "../src/shared"
      require "../src/commands/cluster"
      require "../src/commands/start"
      require "../src/commands/build"
    ]

    command "CLI.cluster.create", context, ->
      Cluster.create()

    command "CLI.cluster.expand", context, ->
      Cluster.expand cluster: "violent-aftermath", count: 3

    command "CLI.start", context, ->
      chdir shared.test.app.root
      start()

    command "CLI.build", context, ->
      chdir shared.test.app.root
      build()
