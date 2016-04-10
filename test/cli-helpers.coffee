assert = require "assert"
{all} = require "when"
{async, isArray, chdir, w} = require "fairmont"
{command} = require "./helpers"

module.exports = (context) ->

  context.test "CLI", (context) ->

    [
      shared
      CLI
    ] = yield all [
      require "../src/shared"
      require "../src/cli"
    ]

    command "CLI.cluster.create", context, ->
      CLI w "cluster create"

    command "CLI.cluster.expand", context, ->
      CLI w "cluster expand violent-aftermath -n 3"

    command "CLI.cluster.contract", context #, ->
      # CLI w "cluster contract violent-aftermath --count 2"

    command "CLI.cluster.rm", context, ->
      CLI w "cluster rm violent-aftermath"

    context.test "CLI.cluster.ls", ->
      assert "violent-aftermath" in (yield CLI w "cluster ls")

    command "CLI.cluster.ps", context, ->
      CLI w "cluster ps violent-aftermath"

    command "CLI.cluster.env", context, ->
      CLI w "cluster env violent-aftermath"

    context.test "CLI.cluster.get", ->
      assert.equal "us-west-1",
        yield CLI w "cluster get violent-aftermath region"

    command "CLI.build", context, ->
      chdir shared.test.app.root
      CLI w "build"

    command "CLI.start", context, ->
      chdir shared.test.app.root
      CLI w "start"

    command "CLI.run", context, ->
      chdir shared.test.app.root
      CLI w "run"
