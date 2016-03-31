{async, merge, read} = require "fairmont"
{write} = require "panda-rw"
{yaml, json} = require "../serialize"
render = require "../template"
Tmp = require "../tmp"

_exports = do async ->

  shared = yield require "../shared"
  run = yield require "../run"
  {getELB} = yield require "./aws"
  Cluster = yield require "../cluster"

  build = async (name, data) ->

  update = async (type, cluster, data) ->
    # merge cluster with update-specific data
    data = merge cluster, data
    # extract the zoneId
    {zoneId} = data
    # create tempfile and write JSON string to it
    file = Tmp.file() + ".json"
    template = yield read shared.aws.dns[type]
    yield write file, yaml render template, data
    # run the update
    yield run "aws.route53.change-resource-record-sets", {zoneId, file}

  H =

    a: ({cluster, node, ip, comment}) ->
      update "a", cluster, {node, ip, comment}

    alias: async ({cluster, domain, subdomain, comment}) ->
      elb = yield getELB cluster.name
      {zoneId} = yield run "aws.route53.list-hosted-zones-by-name", {domain}
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

    srv: async ({cluster, protocol, subdomain, targets, comment}) ->
      yield update "srv", cluster, {protocol, subdomain, targets, comment}

      # Temporary hack--we assume www is also the apex record,
      # so we add a second SRV for the empty value, ex: _._http.
      if subdomain == "www"
        yield update "srv", cluster, {protocol, subdomain: "", targets, comment}

module.exports = _exports
