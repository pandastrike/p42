Path = require "path"
{reduce, reject, async, isFunction, lsR, include, mkdirp} = require "fairmont"
messages = require "panda-messages"

expand = (current, part) -> current[part] ?= {}
blank = (part) -> part == ''

# Build an object whose properties correspond to paths
paths = async (root) ->
  object = {root}
  # Go through all the files in root...
  for path in (yield lsR root)
    # get the directory and names for the relative paths
    {dir, name} = Path.parse Path.relative root, path
    # descend into the object based on the path...
    parent = reduce expand, object,
      # ... unless the relative path is itself a filename
      reject blank, dir.split Path.sep
    # set the corresponding property of the parent
    # (if path is a filename, parent will be object)
    parent[name] = path
  object

loggers = async (shared, loggers = {}) ->

  {message} = yield messages shared.messages

  {helpers, TmpFile, Stream, Memory, Composite} = yield require "./logger"

  wrap = (helpers, wrapped = {}) ->
    for name, fn of helpers when isFunction fn
      do (name, fn) ->
        wrapped["_#{name}"] = fn
        wrapped[name] = (key, data = {}) ->
          fn message key, data

    wrapped.bye = (key, data = {}) ->
      wrapped.error key, data
      process.exit 1

    wrapped._self = helpers._self
    wrapped

  # composite loggers
  status = wrap helpers Composite.create loggers:
    debug: yield TmpFile.create name: "debug", level: "debug"
    stderr: Stream.create stream: process.stderr, level: "info"

  # command logger
  command = helpers Composite.create
    loggers:
      stderr: Stream.create stream: process.stderr, level: "emerg"

  # output logger for actual command output, ex: list of clusters
  output = helpers Composite.create
    loggers:
      stdout: Stream.create stream: process.stdout, level: "info"

  {output, status, command}

_exports = do async ->

  # each p42 user has their own config directory
  config = Path.join process.env.HOME, ".config", "p42"
  yield mkdirp config
  # global settings
  settings = {}
  # each application has a run directory
  run = "run"
  # paths to various shared files
  share = yield paths Path.join __dirname, "..", "share"
  test = yield paths Path.join __dirname, "..", "test", "data"
  test.app.root = Path.join test.root, "app"
  # set up loggers
  loggers = yield loggers share
  # build the shared object
  include share, {config, run, settings, test, loggers}

module.exports = _exports
