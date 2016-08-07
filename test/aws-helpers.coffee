assert = require "assert"
{async} = require "fairmont"
{read} = require "panda-rw"
{command} = require "./helpers"

module.exports = (context) ->

  context.test "AWS", (context) ->

    AWSHelpers = yield require "../src/helpers/aws"

    command "AWS.createStack", context, ->
      AWSHelpers.createStack "preventative-malpractice"

    command "AWS.getStack", context, async ->
      stack = yield AWSHelpers.getStack "preventative-malpractice"
      assert stack.vpcId?
      assert stack.zoneId?

      # test the AZ parsing
      assert.equal stack.az, 'us-west-1a'
      assert.equal stack.region, 'us-west-1'
      assert.equal stack.zone, 'a'

    command "AWS.removeStack", context, ->
      AWSHelpers.removeStack "preventative-malpractice"

    command "AWS.setSecurityGroups", context, ->
      AWSHelpers.setSecurityGroups
        vpcId: "test-vpc-00"
        instance: "preventative-malpractice-01"
        groups: [
          "default"
          "docker-machine"
        ]

    command "AWS.getELB", context, async ->
      {zoneId} = yield AWSHelpers.getELB "violent-aftermath"
      assert.equal "test-zone-00", zoneId

    command "AWS.registerWithELB", context, ->
      AWSHelpers.registerWithELB
        instanceId: "test-instance-00"
        cluster: "vodka-martini"

    command "AWS.getRepository", context, async ->
      {repositoryId} = yield AWSHelpers.getRepository "blurb9-api"
      assert.equal repositoryId, "test-repo-00"

    # TODO: check generated policy JSON
    command "AWS.createRepository", context, ->
      AWSHelpers.createRepository "blurb9-api"

    command "AWS.getRegistryDomain", context, async ->
      assert.equal "123.registry.test.com",
        yield AWSHelpers.getRegistryDomain()
