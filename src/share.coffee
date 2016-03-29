Path = require "path"
{reduce, reject, async, glob, mkdirp} = require "fairmont"
# {read} = require "panda-rw"

buildTreeFromPaths = async (object) ->

  expand = (current, part) -> current[part] ?= {}
  blank = (part) -> part == ''

  for path in (yield glob "**/*", object.root)
    {dir, name} = Path.parse Path.relative object.root, path
    parent = reduce expand, object,
      reject blank, dir.split Path.sep
    parent[name] = path

  object

shared = do async ->
  root = Path.join __dirname, "..", "share"
  config = Path.join process.env.HOME, ".config", "p42"
  yield mkdirp config
  yield buildTreeFromPaths {root, config}

module.exports = shared
