{async, memoize} = require "fairmont"
messages = require "panda-messages"
mstreams = require "memory-streams"
Logger = require "./logger"


# A function to generate helper methods, which define a logger and
# a bunch of closurs on the logger. So instead of:
#
#   Log.info "blurg", "this is a test"
#
# we can simply write:
#
#   log.info "this is a test"
#
# In addition, we add some helpers for use messages. So instead of:
#
#   log.info message "fubar", name: "baz"
#
# We can simply write:
#
#   msg "fubar", name: "baz"
#
# Or, for critical errors:
#
#   bye "fubar", name: "baz"
#

logger = memoize async (name) ->

  shared = yield require "./shared"
  self = (Logger.dictionary[name] ?= yield Logger.create {name})

  {message} = yield messages shared.messages

  helpers =

    log: -> Logger.log self, arguments...

    msg: (key, data = {}) ->
      Logger.info self, message key, data

    bye: (key, data = {}) ->
      Logger.error self, message key, data
      process.exit 1

  helpers.log.read = -> Logger.read self
  helpers.log.clear = -> Logger.clear self

  for key, value of Logger.levels
    do (key) ->
      helpers.log[key] = -> Logger[key] self, arguments...

  helpers

module.exports = logger
