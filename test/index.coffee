Amen = require "amen"
foundation = require "./foundation"
AWSHelpers = require "./aws-helpers"
DNSHelpers = require "./dns-helpers"
dockerHelpers = require "./docker-helpers"
CLIHelpers = require "./cli-helpers"
global.p = -> console.error arguments...




Amen.describe "p42", (context) ->

  foundation context

  context.test "helpers", (context) ->

    AWSHelpers context
    DNSHelpers context
    dockerHelpers context

  CLIHelpers context
