Path = require "path"
{reduce, reject, async, lsR, include, mkdirp} = require "fairmont"

expand = (current, part) -> current[part] ?= {}
blank = (part) -> part == ''

# Build an object whose properties correspond to paths
build = async (root) ->
  object = {}
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

shared = do async ->
  
  # each p42 user has their own config directory
  config = Path.join process.env.HOME, ".config", "p42"
  yield mkdirp config
  # each application has a run directory
  run = "run"
  # global dry run setting
  dryRun = false
  # paths to various shared files
  root = Path.join __dirname, "..", "share"
  # build the shared object
  include yield (build root), {root, config, run, dryRun}

module.exports = shared
