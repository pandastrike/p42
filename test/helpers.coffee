assert = require "assert"
{promise} = require "when"
F = require "fairmont"
{async, sleep, zip, pair} = F
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
readFiles = async (s) ->
  if (paths = s.match /file:\/\/\/[\w\/\-\.]+/)?
    for path in paths
      JSON.stringify JSON.parse (yield F.read (path.replace /file:\/\//g, ""))


sanitize = (s) ->
  s.replace /file:\/+[\w\/\-]+/g, "file://<path>"

# Run a test, comparing the command log to an expected command log
command = (name, context, f) ->

  # Define a test...
  context.test name, ->

    # Synchronize the test...
    yield synchronize async ->

      # Make sure the dryRun flag is set
      shared = yield require "../src/shared"
      shared.dryRun = true

      # Get the command logger helpers and clear the log
      logger = require "../src/message-logger"
      {log} = yield logger "commands"
      yield log.clear()

      # Actually run the test, and wait for the results
      yield f()

      # Read the log and sanitize the results
      actual = yield log.read()
      contents = yield readFiles actual

      # Get the expectations for this test
      expectations = yield read shared.test.expectations
      expected =
        commands: expectations[name]
        files: expectations["#{name}-files"]

      # Compare the expectation with the actual results
      # We catch failures and log them to the console in
      # detail to make it easier to debug.
      try
        assert (sanitize actual) == expected.commands
      catch error
        console.error """
          [ #{name} ]

          ACTUAL
          #{actual}

          EXPECTED
          #{expected.commands}
        """
        # rethrow the error so the test fails
        throw error

      # now compare files
      try
        assert (!(contents?) && !(expected.files?)) ||
          (contents.length == expected.files?.length)

        if contents?
          for [actual, _expected] in (zip pair, contents, expected.files)
            assert.equal actual, _expected

      catch error

        console.error """

          [ #{name} - files ]

          ACTUAL
          #{contents}

          EXPECTED
          #{expected.files}
        """

        throw error


module.exports = {command, synchronize}
