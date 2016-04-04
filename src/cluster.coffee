{basename, join} = require "path"
{async, curry, collect, flow, map, isFile, mkdirp, rm, glob, sleep} = require "fairmont"
basename = do (basename) -> curry (extension, path) -> basename path, extension
{read, write} = require "panda-rw"
Tmp = require "./tmp"
{yaml, json} = require "./serialize"

_exports = do async ->

  shared = yield require "./shared"
  run = yield require "./run"
  {createStack, getStack, removeStack} = yield require "./helpers/aws"
  shared.clusters = join shared.config, "clusters"
  yield mkdirp shared.config.clusters

  Cluster =

    join: (name) -> join shared.clusters, "#{name}.yaml"

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

    remove: async (name) ->
      yield removeStack name
      # TODO: find a way to re-create the cluster
      # YAML file for tests that depend on it
      rm Cluster.join name unless shared.dryRun

    list: ->
      collect flow [
        glob "*.yaml", shared.clusters
        map basename ".yaml"
      ]

module.exports = _exports
