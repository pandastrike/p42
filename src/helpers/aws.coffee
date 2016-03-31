{async} = require "fairmont"
{read, write} = require "panda-rw"
{yaml, json} = require "../serialize"
Tmp = require "../tmp"

_exports = do async ->

  shared = yield require "../shared"
  run = yield require "../run"

  H =

    getInstance: (instance) -> run "aws.ec2.describe-instances", {instance}

    getSecurityGroup: ({vpcId, group}) ->
      run "aws.ec2.describe-security-groups", {vpcId, group}

    setSecurityGroups: async ({vpcId, instance, groups}) ->
      groupIds = for group in groups
        (yield H.getSecurityGroup {vpcId, group})
        .groupId
      {instanceId} = yield H.getInstance instance
      yield run "aws.ec2.modify-instance-attribute", {instanceId, groupIds}

    getELB: (cluster) -> run "aws.elb.describe-load-balancers", {cluster}

    registerWithELB: ({cluster, instanceId}) ->
      run "aws.elb.register-instances-with-load-balancer", {cluster, instanceId}

    getRegistryURL: async ->
      (yield run "aws.ecr.get-authorization-token").url

    getRegistryDomain: async ->
      (yield H.getRegistryURL()).replace /^https:\/\//, ''

    getRepository: (repository) ->
      run "aws.ecr.describe-repositories", {repository}

    createRepository: async (repository) ->
      yield run "aws.ecr.create-repository", {repository}
      policy = json yield read shared.aws.ecr.policy
      yield run "aws.ecr.set-repository-policy", {repository, policy}

    createStack: async (stack) ->
      file = yield Tmp.file() + ".json"
      yield write file, yield read shared.aws.cf.vpc
      run "aws.cloudformation.create-stack", {stack, file}

    removeStack: (stack) ->
      run "aws.cloudformation.delete-stack", {stack}

    getStack: async (stack) ->
      stackData = yield run "aws.cloudformation.describe-stacks", {stack}
      stackData.name = stack
      stackData.region = stackData.az[..-2]
      stackData.zone = stackData.az[-1..-1]
      stackData

module.exports = _exports
