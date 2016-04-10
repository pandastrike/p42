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

    # silence tty logging for commands
    # (we can't simply delete the tty logger, because the
    # CLI will try to set it when --dry-run is set)
    Logger = require "../src/logger"
    shared.loggers.command._self.loggers.tty = Logger.Memory.create()

    AWSHelpers context
    DNSHelpers context
    dockerHelpers context

  CLIHelpers context
