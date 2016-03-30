Path = require "path"
{wrap, reduce, reject, async, glob, mkdirp} = require "fairmont"
once = (f) -> -> k = f() ; f = wrap k ; k

buildTreeFromPaths = async (object) ->

  expand = (current, part) -> current[part] ?= {}
  blank = (part) -> part == ''

  for path in (yield glob "**/*", object.root)
    {dir, name} = Path.parse Path.relative object.root, path
    parent = reduce expand, object,
      reject blank, dir.split Path.sep
    parent[name] = path

  object

init = once async ->
  root = Path.join __dirname, "..", "share"
  config = Path.join process.env.HOME, ".config", "p42"
  dryRun = false
  yield mkdirp config
  yield buildTreeFromPaths {root, config, dryRun}

module.exports = init
