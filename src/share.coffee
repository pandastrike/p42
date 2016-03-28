Path = require "path"
{reduce, reject, async, glob, mkdirp} = require "fairmont"
# {read} = require "panda-rw"

buildTreeFromPaths = async ->
  expand = (current, part) -> current[part] ?= {}
  blank = (part) -> part == ''

  for path in (yield glob "**/*", Share.root)
    {dir, name} = Path.parse Path.relative Share.root, path
    parent = reduce expand, Share,
      reject blank, dir.split Path.sep
    parent[name] = path

Share =
  root: Path.join __dirname, "..", "share"
  join: _join = (names...) -> Path.join Share.root, names...
  config: Path.join process.env.HOME, ".config", "p42"
  init: do (firstTime = true) ->
    async ->
      if firstTime
        firstTime = false
        yield buildTreeFromPaths()
        yield mkdirp Share.config

module.exports = Share
