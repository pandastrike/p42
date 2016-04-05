FS = require "fs"
{curry, go, map, pull, push, async, include, w, empty,
Type, isType, isKind, isString, isArray, isWritable,
toString, Method, read, write} = require "fairmont"

# special version of include that won't
# overwrite with a null value
defaults = (target, objects...)->
  for object in objects
    for key, value of object when value?
      target[key] = value
  target

Tmp = require "./tmp"

Logger = Type.define()

include Logger,

  defaults:
    level: "info"

  # RFC5424 syslog levels
  levels: do (levels={}) ->
    for level, index in w "emerg alert crit error warning notice info debug"
      do (level, index) -> levels[level] = index
    levels

  create: async (type, options) ->
    defaults (yield Type.create type), Logger.defaults, options

# TODO: formatter support
# We don't use the level in the output, nor include a timestamp,
# and so on. That's to avoid messing with the tests, which rely
# on clean output. With a formatter, we could just set the
# formatter when testing to be as below and otherwise more useful.
Logger.log = log = Method.create()

Method.define log, (isKind Logger), isString, (-> true),
  (logger, level, data...) ->
    if Logger.levels[logger.level] >= Logger.levels[level]
      log logger.sink, level, data...

Method.define log, isWritable, isString, (-> true),
  (stream, level, data...) ->
    go [
      data
      map toString
      map write stream
      pull
    ]

Logger.Stream = Type.define Logger

include Logger.Stream,

  create: ({stream, level}) ->
    sink = stream
    Logger.create Logger.Stream, {stream, sink, level}

Logger.File = Type.define Logger.Stream

include Logger.File,

  create: ({path, level}) ->
    stream = sink = FS.createWriteStream path
    Logger.create Logger.File, {stream, sink, path, level}

Logger.TmpFile =

  create: async ({name, level}) ->
    Logger.File.create {path: yield Tmp.file "#{name}.log", level}

Logger.Memory = Type.define Logger

include Logger.Memory,

  create: ({level} = {}) ->
    content = sink = []
    Logger.create Logger.Memory, {sink, content, level}

Method.define log, isArray, isString, (-> true),
  (array, level, data...) ->
    for item in data
      push array, toString item

Logger.Composite = Type.define Logger

include Logger.Composite,

  create: ({loggers}) ->
    Logger.create Logger.Composite, {loggers}

Method.define log, (isKind Logger.Composite), isString, (-> true),
  ({loggers}, level, data...) ->
    (log logger, level, data...) for logger in loggers

Logger.Helpers = do (helpers = {}) ->
  for level, index of Logger.levels
    do (level, index) ->
      helpers[level] = (logger, data...) ->
        log logger, level, data...
  helpers

Logger.helpers = (logger, helpers = {}) ->
  for name, fn of Logger.Helpers
    helpers._self = logger
    do (name, fn) ->
      helpers[name] = -> fn logger, arguments...
  helpers

module.exports = Logger
