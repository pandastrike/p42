{join} = require "path"
YAML = require "js-yaml"
{async, call, read, readdir, write, abort, includes} = require "fairmont"

Errors =
  invalidBranch: (branch) ->
    abort "p42: Invalid branch: #{branch}"
  invalidCluster: (cluster) ->
    abort "p42: Invalid cluster: #{cluster}"
  invalidConfig: ->
    abort """
      p42: Invalid application configuration.
      Try running: p42 init
    """
  errorWritingConfig: ->
    abort "p42: Unexpected error updating application configuration."

Usage =
  main: ->
    abort "Usage: p42 target [add|rm|remove|mv|rename] <branch> <cluster>"
  add: ->
    abort "Usage: p42 target add <branch> <cluster>"
  remove: ->
    abort "Usage: p42 target [remove|rm] <branch> <cluster>"
  rename: ->
    abort "Usage: p42 target [rename|mv] <branch> <branch>"

isBranch = (name) -> true

isCluster = async (name) ->
  includes name,
    yield readdir join process.env.HOME,
      ".config", "p42", "clusters"



Config = do (configPath=join ".", "p42.yaml") ->

  read: async ->
    try
      config = YAML.safeLoad yield read configPath
      config.clusters ?= {}
      config
    catch
      Errors.invalidConfig()

  write: async (config) ->
    try
      yield write configPath, YAML.safeDump config
    catch
      Errors.errorWritingConfig()


Target =

  add: async (branch, cluster) ->
    Usage.add() if !(branch? && cluster?)
    if ! isBranch branch
      Errors.invalidBranch branch
    if ! yield isCluster cluster
      Errors.invalidCluster cluster

    config = yield Config.read()
    config.clusters[branch] = cluster
    yield Config.write config

  remove: async (branch) ->
    Usage.remove() if !branch?
    if ! isBranch branch
      Errors.invalidBranch branch

    config = yield Config.read()
    delete config.clusters[branch]
    yield Config.write config

  rename: async (before, after) ->
    Usage.rename() if !(before? && after?)
    if ! isBranch after
      Errors.invalidBranch after

    config = yield Config.read()
    config.clusters[after] = config.clusters[before]
    delete config.clusters[before]
    yield Config.write config

Target.rm = Target.remove
Target.mv = Target.rename

[action, rest...] = process.argv[2..]

if Target[action]?
  Target[action](rest...)
else
  Usage.main()
