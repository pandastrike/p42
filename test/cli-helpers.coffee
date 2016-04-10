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

    run = (string) -> CLI w "#{string} --dry-run"

    command "CLI.cluster.create", context, ->
      run "cluster create"

    command "CLI.cluster.expand", context, ->
      run "cluster expand violent-aftermath -n 3"

    command "CLI.cluster.contract", context #, ->
      # run "cluster contract violent-aftermath --count 2"

    command "CLI.cluster.rm", context, ->
      run "cluster rm violent-aftermath"

    context.test "CLI.cluster.ls", ->
      assert "violent-aftermath" in (yield run "cluster ls")

    command "CLI.cluster.ps", context, ->
      run "cluster ps violent-aftermath"

    command "CLI.cluster.env", context, ->
      run "cluster env violent-aftermath"

    context.test "CLI.cluster.get", ->
      assert.equal "us-west-1",
        yield run "cluster get violent-aftermath region"

    command "CLI.build", context, ->
      chdir shared.test.app.root
      run "build"

    command "CLI.start", context, ->
      chdir shared.test.app.root
      run "start"

    command "CLI.run", context, ->
      chdir shared.test.app.root
      run "run"
