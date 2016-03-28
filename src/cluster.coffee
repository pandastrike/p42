{join} = require "path"
{exit, isFile, isDirectory,sleep} = require "fairmont"
{read, write} = require "panda-rw"
mktemp = ?
json = JSON.toString

Cluster =

  path: -> join process.env.HOME, ".config", "p42", "clusters"

  mkPath: (name) -> join Cluster.path, "#{name}.yaml"

  mkDir: async ->
    if !(yield exist Cluster.path)
      mkdirp Cluster.path

  load: async (name) ->
    path = Cluster.mkPath name
    if yield isFile path
      read Cluster.mkPath name
    else
      bye "cluster.not-found", name

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
    resolve = async (name) ->
      if name?
        Cluster.load name
      else
        {cluster} = yield Application.load()
        cluster

  remove: (name) ->
    run "aws.cloudformation.delete-stack" {stack: name}
    rm Cluster.mkPath name
