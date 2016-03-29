{async, wrap} = require "fairmont"
{read} = require "panda-rw"
json = JSON.toString
once = (f) -> -> k = f() ; f = wrap k ; k

init = once async ->

  {run} = Commands = yield do (require "../run")

  AWSHelpers =

    getInstance: (instance) -> run "aws.ec2.describe-instances", {instance}

    getSecurityGroup: ({vpcId, group}) ->
      run "aws.ec2.describe-security-groups", {vpcId, group}

    setSecurityGroups: async ({vpcId, instance, groups}) ->
      groupIds = (yield getSecurityGroup {vpcId, group}) for group in groups
      {instanceId} = yield getInstance instance
      run "aws.ec2.modify-instance-attribute", {instanceId, groupIds}

    getELB: (cluster) -> run "aws.elb.describe-load-balancers", {cluster}

    registerWithELB: ({cluster, instanceId}) ->
      run "aws.elb.register-instances-with-load-balancer", {cluster, instanceId}

    getRegistryURL: -> run aws.ecr.get-authorization-token

    getRegistryDomain: -> getRegistryURL().replace /^https:\/\//, ''

    getRepository: (repository) ->
      run "aws.ecr.describe-repositories", {repository}

    createRepository: (repository) ->
      if !(yield getRepository repository)?
        yield run "aws.ecr.create-repository", {repository}
        policy = json yield read "#{share}/ecr/policy.yaml"
        run "aws.ecr.set-repository-policy", {repository, policy}

    createStack: async (stack) ->
      file = (yield mktemp()) + ".json"
      write file, (json yield read "#{share}/cf/vpc.yaml")
      run "aws.cloudformation.create-stack", {stack, file}

    getStack: async (stack) ->
      stackData = yield run "aws.cloudformation.describe-stacks", {stack}
      stackData.name = stack
      stackData.region = stackData.az[..-2]
      stackData.zone = stackData.az[-1..-1]
      stackData

module.exports = init
