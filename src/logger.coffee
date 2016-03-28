FS = require "fs"
{async, read, write} = require "fairmont"
Tmp = require "./tmp"

# This is a very simple logger. This is, to some extent, intentional.
# I played around some other loggers, ex: Winston, but the resulting
# code, at least for what we need here, was more complex, not less.
# We may want to revisit this as we look at adding new features:

# TODO: add support for logging levels
# TODO: add support for formats (ex: JSON)
# TODO: add support for S3, syslog?

loggers = {}

Logger =

  create: async (name) ->
    FS.createWriteStream (yield Tmp.file "#{name}.log")

  get: async (name) ->
    loggers[name] ?= yield Logger.create name

  log: async (name, things...) ->
    stream = yield Logger.get name
    for thing in things
      yield write stream, thing.toString()
      yield write stream, "\n"

  read: (name) ->
    if ({path} = loggers[name])?
      read path

  stream: (name) ->
    if ({path} = loggers[name])?
      FS.createReadStream path

  show: (name, stream = process.stdout) ->
    if ({path} = loggers[name])?
      FS.createReadStream path
      .pipe stream

  clear: (name) ->
    if ({path} = loggers[name])?
      write path, ''

module.exports = Logger
