Amen = require "amen"
foundationTests = require "./foundation-tests"
dockerHelpers = require "./docker-helpers"
CLIHelpers = require "./cli-helpers"
global.p = -> console.error Date.now(), arguments...



# Helper tests test the p42 helpers, as opposed to the test
# helpers in ./helpers
helperTests = require "./helper-tests"

Amen.describe "p42", (context) ->

  foundationTests context

  helperTests context

  dockerHelpers context

  CLIHelpers context
