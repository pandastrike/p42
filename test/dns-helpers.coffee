assert = require "assert"
{async} = require "fairmont"
{read} = require "panda-rw"
{command} = require "./helpers"

module.exports = (context) ->

  context.test "DNS", (context) ->

    DNSHelpers = yield require "../src/helpers/dns"
    shared = yield require "../src/shared"
    cluster = yield read shared.test.clusters["violent-aftermath"]

    # TODO: check generated update JSON files

    command "DNS.A", context, ->
      DNSHelpers.a
        cluster: cluster
        name: "blurb9-www-00"
        ip: "192.168.0.42"
        comment: "this is a test"

    command "DNS.Alias", context, ->
      DNSHelpers.alias
        cluster: cluster
        subdomain: "foo"
        domain: "bar.com"
        comment: "this is a test"

    command "DNS.SRV", context, ->
      DNSHelpers.srv
        cluster: cluster
        protocol: "http"
        subdomain: "www"
        targets:
          host: "www-00"
          port: "32768"
        comment: "this is a test"
