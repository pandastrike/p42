Amen = require "amen"
foundationTests = require "./foundation-tests"

# Helper tests test the p42 helpers, as opposed to the test
# helpers in ./helpers
helperTests = require "./helper-tests"

Amen.describe "p42", (context) ->

  foundationTests context

  helperTests context
