assert = require "assert"
{all} = require "when"
{async, isArray, chdir, w} = require "fairmont"
Logger = require "../src/logger"
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


    run = async (string) ->
      # Redirect command output so we can inspect it
      logger = Logger.Memory.create()
      shared.loggers.output._self.loggers.stdout = logger
      yield CLI w "#{string} --dry-run"
      logger.sink

    command "CLI.cluster.create", context, ->
      run "cluster create"

    command "CLI.cluster.expand", context, ->
      run "cluster expand violent-aftermath -n 3"

    command "CLI.cluster.contract", context #, ->
      # run "cluster contract violent-aftermath --count 2"

    command "CLI.cluster.rm", context, ->
      run "cluster rm violent-aftermath"

    command "CLI.cluster.ls", context, async ->
      assert (yield run "cluster ls").indexOf("violent-aftermath") != -1

    command "CLI.cluster.ps", context, ->
      run "cluster ps violent-aftermath"

    command "CLI.cluster.env", context, ->
      run "cluster env violent-aftermath"

    command "CLI.cluster.get", context, async ->
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
