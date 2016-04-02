Path = require "path"
{reduce, reject, async, lsR, include, mkdirp} = require "fairmont"

expand = (current, part) -> current[part] ?= {}
blank = (part) -> part == ''

# Build an object whose properties correspond to paths
build = async (root) ->
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

_exports = do async ->

  # each p42 user has their own config directory
  config = Path.join process.env.HOME, ".config", "p42"
  yield mkdirp config
  # each application has a run directory
  run = "run"
  # global dry run setting
  dryRun = false
  # paths to various shared files
  share = yield build Path.join __dirname, "..", "share"
  test = yield build Path.join __dirname, "..", "test", "data"
  test.app.root = Path.join test.root, "app"
  # build the shared object
  include share, {config, run, dryRun, test}

module.exports = _exports
