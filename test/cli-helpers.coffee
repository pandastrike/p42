assert = require "assert"
{all} = require "when"
{async, isArray, chdir} = require "fairmont"
{command} = require "./helpers"

module.exports = (context) ->

  context.test "CLI", (context) ->

    [
      shared
      Cluster
      build
      start
      run
    ] = yield all [
      require "../src/shared"
      require "../src/commands/cluster"
      require "../src/commands/build"
      require "../src/commands/start"
      require "../src/commands/run"
    ]

    command "CLI.cluster.create", context, ->
      Cluster.create()

    command "CLI.cluster.expand", context, ->
      Cluster.expand name: "violent-aftermath", count: 3

    command "CLI.cluster.contract", context #, ->
      # Cluster.contract cluster: "violent-aftermath", count: 3

    command "CLI.cluster.rm", context, ->
      Cluster.rm "violent-aftermath"

    context.test "CLI.cluster.ls", ->
      assert "violent-aftermath" in (yield Cluster.ls())

    command "CLI.cluster.ps", context, ->
      Cluster.ps "violent-aftermath"

    command "CLI.cluster.env", context, ->
      Cluster.env "violent-aftermath"

    context.test "CLI.cluster.get", ->
      assert.equal "us-west-1",
        yield Cluster.get "violent-aftermath", "region"

    command "CLI.build", context, ->
      chdir shared.test.app.root
      build()

    command "CLI.start", context, ->
      chdir shared.test.app.root
      start()

    command "CLI.run", context, ->
      chdir shared.test.app.root
      run()
