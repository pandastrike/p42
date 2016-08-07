assert = require "assert"
Path = require "path"
{async, isDirectory, read} = require "fairmont"
{synchronize} = require "./helpers"

# These tests mostly just make sure all the underlying mechanics
# of the app work. These include:
#
# - the shared configuration
# - tmp file generation
# - logging and logger helpers
# - running shell commands
#
# These are by no means exhaustive since that would be in some cases
# pretty difficult. (Ex: verifying that the tmp files are cleaned up
# on process exit.) It's more a smoke test.
#
# They're also something of a scaffolding. Consider removing these
# tests later once the app is stable. They don't add much, if anything,
# to the coverage and are thus mostly useful for debugging.

module.exports = (context) ->

  context.test "foundation", (context) ->

    context.test "share", ->
      shared = yield require "../src/shared"
      assert shared.test.expectations?

    context.test "tmp", ->
      Tmp = require "../src/tmp"
      {dir, base} = Path.parse (yield Tmp.file "test.txt")
      assert.equal base, "test.txt"
      assert.equal true, (yield isDirectory dir)

    context.test "logger", (context) ->

      Logger = yield require "../src/logger"

      context.test "memory", ->
        logger = Logger.Memory.create()
        {info} = Logger.helpers logger
        info "this is a test"
        info "this is not a test"
        {content} = logger
        assert.equal content.toString(), "this is a test,this is not a test"

      context.test "file", ->
        logger = yield Logger.TmpFile.create name: "test"
        {info} = Logger.helpers logger
        yield info "this is a test"
        yield info "this is not a test"
        content = yield read logger.path
        assert.equal content, "this is a test\nthis is not a test\n"

      context.test "stream"
      # context.test "stream", ->
        # logger = Logger.Stream.create stream: process.stdout
        # {info} = Logger.helpers logger
        # yield info "this is a test"
        # yield info "this is not a test"

      context.test "composite"
      # context.test "composite", ->
      #   stdout = yield Logger.Stream.create stream: process.stdout
      #   tmpfile = yield Logger.TmpFile.create name: "test"
      #   logger = Logger.Composite.create loggers: [ stdout, tmpfile ]
      #   {info} = Logger.helpers logger
      #   info "this is a test"
      #   info "this is not a test"


      context.test "message logger"

      context.test "shell subprocess",# ->
        # createShell = require "../src/sh"
        # shell = createShell process.stdout, process.stderr
        # yield shell.run "ls"
        # shell.close()

    context.test "shell runner", ->
      shared = yield require "../src/shared"
      yield synchronize async ->
        shared.settings.dryRun = true
        run = yield require "../src/run"
        {zoneId} = yield run "aws.route53.list-hosted-zones-by-name",
          domain: "fubar.com"
        assert.equal zoneId, "test-zone-00"
