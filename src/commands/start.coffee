{all} = require "when"
{async, empty, isArray} = require "fairmont"
sprintf = require "sprintf"

_exports = do async ->

  [
    AWSHelpers
    DockerHelpers
    DNSHelpers
    Application
    Cluster
  ] = yield all [
    require "../helpers/aws"
    require "../helpers/docker"
    require "../helpers/dns"
    require "../application"
    require "../cluster"
  ]

  {Mixins} = Application

  pull = async (cluster, registry, tag) ->
    for node in yield DockerHelpers.listSwarmNodes cluster
      yield DockerHelpers.env node
      yield DockerHelpers.login()
      yield DockerHelpers.pull {registry, tag}

  start = async (mixin) ->

    {registry, domain} = application = yield Application.load()
    {subdomains, count, discovery} = yield Mixins.load mixin
    cluster = yield Cluster.load application.cluster

    # normalize the mixin config properties
    subdomains = if isArray subdomains then subdomains
    discovery = discovery == true

    # comment for DNS records
    # comment = msg "dns.comment", application
    comment = ""

    tag = "#{application.name}-#{mixin}"
    yield pull cluster.name, registry, tag

    yield DockerHelpers.swarmEnv cluster.name
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
      {name} = yield DockerHelpers.inspect name
      {ip} = yield AWSHelpers.getInstance name

      # Add private DNS A record associating the name with the IP
      yield DNSHelpers.a {cluster, name, ip, comment}

      # save the list of containers so we can set up
      # DNS SRV records later / we only need to do this
      # if discovery is set in the config
      targets.push name if discovery?

      # Add to ELB, if applicable, based on subdomains
      if subdomains?

        AWSHelpers.registerInstanceWithELB {cluster: cluster.name, instanceId}

        # no point in adding an instance to the ELB
        # if we can't find it via public DNS...
        for subdomain in subdomains
          DNSHelpers.alias {cluster: cluster.name, domain, subdomain, comment}

    # Create SRV records for each target,
    # for each protocol the container supports
    for protocol in discovery
      DNSHelpers.srv {protocol, subdomain: mixin, targets, comment}

  async (mixins...) ->
    if empty mixins
      mixins = yield Mixins.list()

    (yield start mixin) for mixin in mixins

module.exports = _exports
