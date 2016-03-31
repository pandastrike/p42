{join} = require "path"
{async, isFile, mkdirp, rmDir, sleep} = require "fairmont"
{read, write} = require "panda-rw"
Tmp = require "./tmp"
{yaml, json} = require "./serialize"

_exports = do async ->

  shared = yield require "./shared"
  run = yield require "./run"
  {createStack, getStack, deleteStack} = yield require "./helpers/aws"
  shared.config.clusters = join shared.config, "clusters"
  yield mkdirp shared.config.clusters

  Cluster =

    join: (name) ->
      join shared.config, "clusters", "#{name}.yaml"

    load: async (name) ->
      path = Cluster.join name
      if yield isFile path
        read path
      else
        # bye "cluster.not-found", name

    save: async (cluster) ->
      yield write (Cluster.join cluster.name), cluster
      cluster

    create: async (name) ->
      yield createStack name
      loop
        # wait 5 seconds before querying status
        yield sleep 5000 unless shared.dryRun
        cluster = yield getStack name
        if cluster.status == "CREATE_COMPLETE"
          break
        else if cluster.status == "CREATE_FAILED"
          bye "cluster.create-failed", {name}

      Cluster.save cluster

    resolve: async (name) ->
      if name?
        yield Cluster.load name
      else
        {cluster} = yield Application.load()
        cluster

    remove: (name) ->
      yield deleteStack name
      rmDir Cluster.join name

module.exports = _exports
