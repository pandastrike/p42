{basename, join} = require "path"
{all} = require "when"
{async, curry, collect, flow, map, isFile, mkdirp, rm, glob, sleep} = require "fairmont"
basename = do (basename) -> curry (extension, path) -> basename path, extension
{read, write} = require "panda-rw"
Tmp = require "./tmp"
{yaml, json} = require "./serialize"
raise = require "./raise"

_exports = do async ->

  [
    shared
    AWSHelpers
    # TODO: somehow there's a circular dependency here
    # Application
  ] = yield all [
    require "./shared"
    require "./helpers/aws"
    # require "./application"
  ]

  {createStack, getStack, removeStack} = AWSHelpers

  shared.clusters = join shared.config, "clusters"
  yield mkdirp shared.config.clusters

  Cluster =

    join: (name) -> join shared.clusters, "#{name}.yaml"

    load: async (name) ->
      path = Cluster.join name
      if yield isFile path
        read path
      else
        raise "cluster.not-found", {name}

    save: async (cluster) ->
      yield write (Cluster.join cluster.name), cluster
      cluster

    create: async (name) ->
      yield createStack name
      loop
        # wait 5 seconds before querying status
        yield sleep 5000 unless shared.settings.dryRun
        cluster = yield getStack name
        if cluster.status == "CREATE_COMPLETE"
          break
        else if cluster.status != "CREATE_IN_PROGRESS"
          raise "cluster.create-failed", {name}

      Cluster.save cluster

    resolve: async (name) ->
      name ?= yield do async ->
        # see above re inline require
        Application = yield require "./application"
        {cluster} = yield Application.load()
        cluster
      yield Cluster.load name

    remove: async (name) ->
      yield removeStack name
      # TODO: find a way to re-create the cluster
      # YAML file for tests that depend on it
      (rm Cluster.join name) unless shared.settings.dryRun

    list: ->
      collect flow [
        glob "*.yaml", shared.clusters
        map basename ".yaml"
      ]

module.exports = _exports
