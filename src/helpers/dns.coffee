Cluster = require "cluster"
{run} = require "commands"
render = (template, data={}) ->

DNSHelpers =

  template: (name) -> read "#{share}/dns/#{name}.yaml"

  build: (name, data) -> json yaml render (yield template name), data

  update: async (type, cluster, data) ->
    # merge cluster with update-specific data
    data = merge (Cluster.load cluster), data
    # extract the zoneId
    {zoneId} = data
    # create tempfile and write JSON string to it
    file = mktemp() + ".json"
    yield write file, yield build "a", data
    # run the update
    yield run "aws.route53.change-resource-record-sets", {zoneId, file}

  a: ({cluster, node, ip, comment}) ->
    update "a", cluster, {node, ip, comment}

  alias: async ({cluster, domain, subdomain, comment}) ->
    {zoneId} = yield run "aws.route53.list-hosted-zones-by-name" {domain}
    elb = yield getELB cluster
    yield update "alias", cluster,
      domain: "#{subdomain}.#{domain}",
      zoneId: zoneId
      elbZoneId: elb.zoneId
      elbDomain: elb.domain
      comment: comment

    # Temporary hack--we assume www is also the apex record,
    # so we add a second alias for apex.
    if subdomain == "www"
      alias {cluster, domain, subdomain: "", comment}

  srv: ({cluster, protocol, subdomain, targets, comment}) ->
    yield update "srv", cluster, {protocol, subdomain, targets, comment}

    # Temporary hack--we assume www is also the apex record,
    # so we add a second SRV for the empty value, ex: _._http.
    if subdomain == "www"
      srv cluster, protocol, "", targets, comment
