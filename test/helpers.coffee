assert = require "assert"
{promise} = require "when"
{async, sleep} = require "fairmont"
{read} = require "panda-rw"

# This ensures that when we're logging the commands for test A,
# we don't interfere with the commands for test B.
synchronize = do (waiting=[]) ->

  # Main run loop. We wait one second before we starting processing
  # functions in the wait queue to ensure the tests are all queued.
  do async ->
    yield sleep 1000
    yield g() while g = waiting.shift()

  # Queuing function for test functions. We return a promise
  # the test can yield on, but all we do is a queue a wrapper fn.
  # The wrapper propagates the result back here from the run loop,
  # resolving the promise the test code is waiting on.
  (f) ->
    promise (resolve, reject) ->
      waiting.push async ->
        try
          # Important to yield here so that the run loop will wait
          # until f completes before running the next fn.
          resolve yield f()
        catch error
          reject error

# Clean up any variability in the command logging so we can
# reliably compare to expectations
sanitize = (s) ->
  s.replace /file:\/+[\w\/\-]+/g, "file:///***"

# Run a test, comparing the command log to an expected command log
command = (name, context, f) ->

  # Define a test...
  context.test name, ->

    # Synchronize the test...
    yield synchronize async ->

      # Make sure the dryRun flag is set
      shared = yield do (require "../src/share")
      shared.dryRun = true

      # Get the command logger helpers and clear the log
      logger = require "../src/message-logger"
      {log} = yield logger "commands"
      yield log.clear()

      # Actually run the test, and wait for the results
      yield f()

      # Read the log and sanitize the results
      actual = sanitize yield log.read()

      # Get the expectations for this test
      expectations = yield read shared.test.expectations
      expected = expectations[name]

      # Compare the expectation with the actual results
      # We catch failures and log them to the console in
      # detail to make it easier to debug.
      try
        assert actual == expected
      catch error
        console.error """
          [ #{name} ]

          ACTUAL
          #{actual}

          EXPECTED
          #{expected}
        """
        # rethrow the error so the test fails
        throw error

module.exports = {command, synchronize}
