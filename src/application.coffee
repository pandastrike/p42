{join} = require "path"
{async, include, isFile, isDirectory, readdir, sh, empty} = require "fairmont"
{read, write} = require "panda-rw"
logger = require "./message-logger"

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


  {bye} = yield logger "output"

  Application =

    create: (definition) -> write "./p42.yaml", definition

    load: async ->

      bye "application.no-configuration" if ! yield isFile "./p42.yaml"
      branch = yield Git.getBranch()

      bye "application.no-branch" if ! branch?
      {name, domain, registry, clusters} = yield read "./p42.yaml"
      cluster = clusters?[branch]
      bye "application.no-target" if !cluster?

      {name, domain, registry, cluster}

    Mixins: Mixins =

      assert: async (name) ->
        if ! yield isFile "./run/#{name}/config.yaml"
          bye "application.bad-mixin"

      list: async ->
        bye "application.nothing-to-run" if ! yield isDirectory "./run"
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

module.exports = _exports
