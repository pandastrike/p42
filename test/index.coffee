assert = require "assert"
Amen = require "amen"
Path = require "path"
{async, isDirectory} = require "fairmont"
{command, synchronize} = require "./helpers"

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

      command "createStack", context, ->
        AWSHelpers.createStack "preventative-malpractice"

      command "removeStack", context, ->
        AWSHelpers.removeStack "preventative-malpractice"

      command "setSecurityGroups", context, ->
        AWSHelpers.setSecurityGroups
          vpcId: "test-vpc-00"
          instance: "preventative-malpractice-01"
          groups: [
            "default"
            "docker-machine"
          ]

      command "getELB", context, async ->
        {zoneId} = yield AWSHelpers.getELB "violent-aftermath"
        assert.equal "test-zone-00", zoneId

      command "registerWithELB", context, ->
        AWSHelpers.registerWithELB
          instanceId: "test-instance-00"
          cluster: "vodka-martini"

      command "getRepository", context, async ->
        {repositoryId} = yield AWSHelpers.getRepository "blurb9-api"
        assert.equal repositoryId, "test-repo-00"

      command "createRepository", context, ->
        AWSHelpers.createRepository "blurb9-api"

      command "getRegistryDomain", context, async ->
        assert.equal "123.registry.test.com",
          yield AWSHelpers.getRegistryDomain()

      context.test "DNS", (context) ->

        DNSHelpers = yield do (require "../src/helpers/dns")

        command "DNS-Alias", context, ->
          DNSHelpers.alias
            cluster: "violent-aftermath"
            subdomain: "foo"
            domain: "bar.com"
            comment: "this is a test"

        command "DNS-SRV", context, ->
          DNSHelpers.srv
            cluster: "violent-aftermath"
            protocol: "http"
            subdomain: "www"
            private: "www-00"
            port: "32768"
            comment: "this is a test"
