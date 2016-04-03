assert = require "assert"
Path = require "path"
{async, isDirectory} = require "fairmont"
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

    context.test "logger", ->
      Logger = require "../src/logger"
      yield Logger.info "fubar", "this is a test"
      yield Logger.info "fubar", "this is not a test"
      content = yield Logger.read "fubar"
      assert.equal content, "this is a test\nthis is not a test\n"

    context.test "message logger", ->
      logger = require "../src/message-logger"
      {msg, log} = yield logger "test"
      yield msg "fubar", name: "baz"
      yield log.error "oops"
      content = yield log.read "test"
      assert.equal content, "this is a test baz\noops\n"

    context.test "shell runner", ->
      shared = yield require "../src/shared"
      yield synchronize async ->
        shared.dryRun = true
        run = yield require "../src/run"
        {zoneId} = yield run "aws.route53.list-hosted-zones-by-name",
          domain: "fubar.com"
        assert.equal zoneId, "test-zone-00"
