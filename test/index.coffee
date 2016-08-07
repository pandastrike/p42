Amen = require "amen"
foundation = require "./foundation"
AWSHelpers = require "./aws-helpers"
DNSHelpers = require "./dns-helpers"
dockerHelpers = require "./docker-helpers"
CLIHelpers = require "./cli-helpers"

Amen.describe "p42", (context) ->

  foundation context

  context.test "helpers", (context) ->

    # Make sure the dryRun flag is set
    shared = yield require "../src/shared"
    shared.settings.dryRun = true

    AWSHelpers context
    DNSHelpers context
    dockerHelpers context

  CLIHelpers context
