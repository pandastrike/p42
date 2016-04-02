assert = require "assert"
{async} = require "fairmont"
{read} = require "panda-rw"
{command} = require "./helpers"

module.exports = (context) ->

  context.test "helpers", (context) ->

    context.test "AWS", (context) ->
      AWSHelpers = yield require "../src/helpers/aws"

      command "createStack", context, ->
        AWSHelpers.createStack "preventative-malpractice"

      command "getStack", context, async ->
        stack = yield AWSHelpers.getStack "preventative-malpractice"
        assert stack.vpcId?
        assert stack.zoneId?

        # test the AZ parsing
        assert.equal stack.az, 'us-west-1a'
        assert.equal stack.region, 'us-west-1'
        assert.equal stack.zone, 'a'

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

      # TODO: check generated policy JSON
      command "createRepository", context, ->
        AWSHelpers.createRepository "blurb9-api"

      command "getRegistryDomain", context, async ->
        assert.equal "123.registry.test.com",
          yield AWSHelpers.getRegistryDomain()

      context.test "DNS", (context) ->

        DNSHelpers = yield require "../src/helpers/dns"
        shared = yield require "../src/shared"
        cluster = yield read shared.test.clusters["violent-aftermath"]

        # TODO: check generated update JSON files

        command "DNS-A", context, ->
          DNSHelpers.a
            cluster: cluster
            name: "blurb9-www-00"
            ip: "192.168.0.42"
            comment: "this is a test"

        command "DNS-Alias", context, ->
          DNSHelpers.alias
            cluster: cluster
            subdomain: "foo"
            domain: "bar.com"
            comment: "this is a test"

        command "DNS-SRV", context, ->
          DNSHelpers.srv
            cluster: cluster
            protocol: "http"
            subdomain: "www"
            targets:
              host: "www-00"
              port: "32768"
            comment: "this is a test"
