{join} = require "path"
{async, wrap, isFile, mkdirp, rmDir, sleep} = require "fairmont"
{read, write} = require "panda-rw"
Tmp = require "./tmp"
{yaml, json} = require "./serialize"
once = (f) -> -> k = f() ; f = wrap k ; k

init = once async ->

  shared = yield do (require "./share")
  {run} = Commands = yield do (require "./run")
  {createStack, deleteStack} = require "./helpers/aws"
  shared.config.clusters = join shared.config, "clusters"
  yield mkdirp root

  Cluster =

    join: (name) ->
      if shared.dryRun
        shared.test.clusters[name]
      else
        join shared.config.clusters, "#{name}.yaml"

    load: async (name) ->
      path = Cluster.join name
      if yield isFile path
        read path
      else
        # bye "cluster.not-found", name

    save: async (cluster) ->
      yield Cluster.mkDir()
      write (Cluster.mkPath cluster.name), cluster

    create: async (name) ->
      yield createStack name
      while true
        # wait 5 seconds before querying status
        yield sleep 5000 unless config.dryRun
        cluster = yield getStack name
        switch cluster.status
          when "CREATE_COMPLETE" then break
          when "CREATE_FAILED" then bye "cluster.create-failed", {name}

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

module.exports = init
