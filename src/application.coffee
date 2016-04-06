{join} = require "path"
{async, include, isFile, isDirectory, readdir, sh, empty} = require "fairmont"
{read, write} = require "panda-rw"
raise = require "./raise"

_exports = do async ->

  shared = yield require "./shared"
  Decorators = yield require "./decorators"

  Git =

    getBranch: async ->
      if shared.dryRun
        "master"
      else
        (yield sh "git symbolic-ref --short -q HEAD")
        .stdout


  Application =

    create: (definition) -> write "./p42.yaml", definition

    load: async ->

      raise "application.no-configuration" if ! yield isFile "./p42.yaml"
      branch = yield Git.getBranch()

      raise "application.no-branch" if ! branch?
      {name, domain, registry, clusters} = yield read "./p42.yaml"
      cluster = clusters?[branch]
      raise "application.no-target" if !cluster?

      {name, domain, registry, cluster}

    Mixins: Mixins =

      assert: async (name) ->
        if ! yield isFile "./run/#{name}/config.yaml"
          raise "application.bad-mixin"

      list: async ->
        raise "application.nothing-to-run" if ! yield isDirectory "./run"
        yield readdir "./run"

      load: async (name) ->
        path = join shared.run, name
        config = join path, "config.yaml"
        include (yield read config), {name, path}

      build: async (mixins...) ->
        application = yield Application.load()
        mixins = if empty mixins then yield Mixins.list() else mixins
        for name in mixins
          yield Mixins.assert name
          mixin = yield Mixins.load name
          yield Decorators[mixin.style]? application, mixin

    Targets:

      add: (target, name) ->
        application = yield Application.load()
        application.clusters[target] = name
        Application.save application

      remove: (target) ->
        application = yield Application.load()
        delete application.clusters[target]
        Application.save application

      rename: (before, after) ->
        application = yield Application.load()
        application.clusters[after] = application.clusters[before]
        Application.save application

module.exports = _exports
