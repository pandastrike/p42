FS = require "fs"
{curry,
async, include, merge, w,
Type, isType,  isString,
Method,
read, write} = require "fairmont"
Tmp = require "./tmp"

createTempStream = async (name) ->
  FS.createWriteStream (yield Tmp.file "#{name}.log")

# TODO: formatter support
# We don't use the level in the output, nor include a timestamp,
# and so on. That's to avoid messing with the tests, which rely
# on clean output. With a formatter, we could just set the
# formatter when testing to be as below and otherwise more useful.
log = (stream, level, thing) -> write stream, "#{thing}\n"

Logger = Type.define()

# This little bit of craziness effectively allows us to define
# logger-based multimethods with parameterizable lookups,
# so we can call them using a string key or a logger object.
adapter = curry (K, F) ->
  M = Method.create()
  L = K M
  Method.define M, (isType Logger), (-> true), F
  Method.define M, (isType Logger), F
  Method.define M, (isString), (-> true), L
  Method.define M, (isString), L
  M

# Returns a multimethod that will create the logger if it doesn't exist.
definitely = adapter (method) ->
  async (name, args...) ->
    logger = (Logger.dictionary[name] ?= yield Logger.create {name})
    method logger, args...

# Returns a multimethod that will do nothing if the logger doesn't exist.
maybe = adapter (method) ->
  (name, args...) ->
    if (logger = Logger.dictionary[name])?
      method logger, args...

include Logger,

  defaults:
    level: "info"

  levels: {} # see below

  dictionary: {}

  create: async ({name, stream}) ->
    stream ?= yield createTempStream name
    include (Type.create Logger), Logger.defaults, {name, stream}

  log: definitely async (logger, level, things...) ->
    if Logger.levels[logger.level] >= Logger.levels[level]
      (yield log logger.stream, level, thing) for thing in things

  read: maybe ({stream}) -> read stream.path

  stream: maybe ({stream}) -> FS.createReadStream path

  show: maybe (logger, sink) -> (Logger.stream logger).pipe sink

  # TODO: I think we need to recreate the stream here
  clear: maybe async (logger) ->
    yield write logger.stream.path, ''
    logger.stream = FS.createWriteStream logger.stream.path

# RFC5424 levels for syslog
for level, index in w "emerg alert crit error warning notice info debug"
  do (level, index) ->
    Logger.levels[level] = index
    Logger[level] = (logger, args...)-> Logger.log logger, level, args...

module.exports = Logger
