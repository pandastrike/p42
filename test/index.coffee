Path = require "path"
assert = require "assert"
{promise} = require "when"
Amen = require "amen"
{async, isDirectory, isWriteStream, sleep} = require "fairmont"
{read} = require "panda-rw"
{EventEmitter} = require "events"

# This ensures that when we're logging the commands for test A,
# we don't interfere with the commands for test B.
synchronize = do (waiting=[]) ->

  # Main run loop. We wait one second before we starting processing
  # functions in the wait queue to ensure the tests are all queued.
  do async ->
    yield sleep 1000
    yield g() while g = waiting.shift()

  # Queuing function defined as 'synchronize'. We return a promise
  # the test can yield on, but all we do is a queue a wrapper fn.
  # The wrapper propagates the result back here from the run loop,
  # resolving the promise the test code is waiting on.
  (f) ->
    promise (resolve, reject) ->
      waiting.push async ->
        try
          # Important to yield here so that the run loop will wait
          # until f completes before running the next fn.
          resolve yield f()
        catch error
          reject error

command = (name, context, f) ->
  context.test name, ->
    yield synchronize async ->
      shared = yield do (require "../src/share")
      shared.dryRun = true
      logger = require "../src/message-logger"
      {msg, log} = yield logger "commands"
      yield log.clear()
      yield f()
      actual = yield log.read()
      expectations = yield read shared.test.expectations
      expected = expectations[name]
      try
        assert.equal actual, expected
      catch error
        console.log """
          [ #{name} ]

          ACTUAL
          #{actual}

          EXPECTED
          #{expected}
        """
        throw error

Amen.describe "p42", (context) ->

  context.test "foundation", (context) ->

    context.test "share", ->
      shared = yield do (require "../src/share")
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
      yield synchronize async ->
        shared = yield do (require "../src/share")
        shared.dryRun = true
        {run} = yield do (require "../src/run")
        {zoneId} = yield run "aws.route53.list-hosted-zones-by-name",
          domain: "fubar.com"
        assert.equal zoneId, "test-dns-00"

  context.test "helpers", (context) ->

    context.test "AWS", (context) ->
      AWSHelpers = yield do (require "../src/helpers/aws")

      command "getRepository", context, async ->
        {repositoryId} = yield AWSHelpers.getRepository "blurb9-api"
        assert.equal repositoryId, "test-repo-00"

      command "createRepository", context, ->
        AWSHelpers.createRepository "blurb9-api"

      command "setSecurityGroups", context, ->
        AWSHelpers.setSecurityGroups
          vpcId: "test-vpc-00"
          instance: "preventative-malpractice-01"
          groups: [
            "default"
            "docker-machine"
          ]

      # command "getRegistryDomain", context, async ->
      #   AWSHelpers.getRegistryDomain()
      #
      # command "getELB", context, async ->
      #   AWSHelpers.getELB "violent-aftermath"
      #
      # command "registerWithELB", context, async ->
      #   AWSHelpers.registerWithELB
      #     instanceId: "test-instance-00"
      #     cluster: "vodka-martini"
      #
      # command "createStack", context, async ->
      #   AWSHelpers.createStack "preventative-malpractice"
      #
      # command "removeStack", context, async ->
      #   AWSHelpers.removeStack "preventative-malpractice"
      #
      # context.test "DNS", (context) ->
      #
      #   DNSHelpers = yield do (require "../src/helpers/dns")
      #
      #   command "Alias", context, async ->
      #     DNSHelpers.alias
      #       cluster: "violent-aftermath"
      #       subdomain: "foo"
      #       domain: "bar.com"
      #       comment: "this is a test"
      #
      #   command "SRV", context, async ->
      #     DNSHelpers.srv
      #       cluster: "violent-aftermath"
      #       protocol: "http"
      #       subdomain: "www"
      #       private: "www-00"
      #       port: "32768"
      #       comment: "this is a test"
