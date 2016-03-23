{join} = require "path"
YAML = require "js-yaml"
{async, call, read, readdir, write, includes} = require "fairmont"
messages = require "./messages"

# TODO: check for valid branch
isBranch = (name) -> true

isCluster = async (name) ->
  includes name, yield readdir process.env.clusters

Config = do (configPath=join ".", "p42.yaml") ->

  read: async ->
    try
      config = YAML.safeLoad yield read configPath
      config.clusters ?= {}
      config
    catch
      abort "invalid-config", config: configPath

  write: async (config) ->
    try
      yield write configPath, YAML.safeDump config
    catch
      abort "error-writing-config"

Target =

  add: async (branch, cluster) ->

    (usage "add") if !(branch? && cluster?)

    if ! isBranch branch
      abort "invalid-branch", {branch}

    if ! yield isCluster cluster
      abort "invalid-cluster", {cluster}

    config = yield Config.read()
    config.clusters[branch] = cluster
    yield Config.write config

  remove: async (branch) ->

    (usage "remove") if !branch?

    if ! isBranch branch
      Errors.invalidBranch branch

    config = yield Config.read()
    delete config.clusters[branch]
    yield Config.write config

  rename: async (before, after) ->

    (usage "rename") if !(before? && after?)

    if ! isBranch after
      Errors.invalidBranch after

    config = yield Config.read()
    config.clusters[after] = config.clusters[before]
    delete config.clusters[before]
    yield Config.write config

Target.rm = Target.remove
Target.mv = Target.rename

run = async (action, rest...) ->

  {usage, abort} = yield messages "target"

  if Target[action]?
    Target[action] rest...
  else
    usage()
