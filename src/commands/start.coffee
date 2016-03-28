AWSHelpers = require "../helpers/aws"
DockerHelpers = require "./helpers/docker"

pull = (cluster, tag) ->
  {registry} = yield Application.load()
  for node in yield AWSHelpers.listSwarmInstances
    yield DockerHelpers.env node
    yield DockerHelpers.login()
    yield DockerHelpers.pull registry, tag

run = (mixin) ->

  application = yield Application.load()
  {cluster, domain} = application
  {subdomains, count, discovery} = yield Mixin.load mixin

  # normalize the mixin config properties
  subdomains = if isArray subdomains then subdomains
  discovery = discovery == true

  # comment for DNS records
  comment = msg "dns.comment", application

  tag = "#{application.name}-#{mixin}"
  yield pull cluster, tag

  yield DockerHelpers.swarmEnv cluster
  yield DockerHelpers.login()

  # TODO: this is a hack. We know that if you're
  # setting up subdomains for a part, that you must
  # want to use standard ports. The ports we expose
  # should be based on some additional piece of
  # information (ex: protocols, like we do with
  # discovery), but for the moment, we're just
  # assuming you want port 80. Note that we're
  # terminating TLS at the ELB so you probably
  # don't want to expose 443.
  if subdomains?
    options = "-p 80:80"
  else
    options = "-P"

  # TODO: Refactoring this loop is tricky because
  # all the pieces here are pretty intertwined:
  #
  # - run the docker container
  #
  # - add the private A record for the container
  #
  # - if we want discovery for this container,
  #   add the container and it's port to a list
  #   so we can later add a private SRV record
  #
  # - possibly add the node running the container
  #   to the ELB if it's advertising a subdomain
  #

  targets = []
  for i in [1..count]

    # run the docker container
    name = "#{application.name}-#{mixin}-#{sprintf '%02d', i}"
    yield DockerHelpers.run {name, tag, options}

    # get the IP for the newly launched instance
    instanceId = yield DockerHelpers.inspect name
    {ip} = yield AWSHelpers.getInstance instanceId

    # Add private DNS A record associating the name with the IP
    yield DNSHelpers.a {name, ip, comment}

    # save the list of containers so we can set up
    # DNS SRV records later / we only need to do this
    # if discovery is set in the config
    targets.push name if discovery?

    # Add to ELB, if applicable, based on subdomains
    if subdomain?

      AWSHelpers.registerInstanceWithELB {cluster, instanceId}

      # no point in adding an instance to the ELB
      # if we can't find it via public DNS...
      for subdomain in subdomains
        DNSHelpers.alias {cluster, domain, subdomain, comment}

  # Create SRV records for each target,
  # for each protocol the container supports
  for protocol in discovery
    DNSHelpers.srv {protocol, subdomain: mixin, targets, comment}

module.exports = (mixins...) ->
  run mixin for mixin in mixins
