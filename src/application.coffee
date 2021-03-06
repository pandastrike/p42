{basename, join} = require "path"
F = {async, include, isFile, isDirectory, glob,
readdir, shell, empty} = require "fairmont"
{read, write} = require "panda-rw"
render = require "./template"
raise = require "./raise"

_exports = do async ->

  shared = yield require "./shared"
  Decorators = yield require "./decorators"

  Git =

    getBranch: async ->
      if shared.settings.dryRun
        "master"
      else
        (yield shell "git symbolic-ref --short -q HEAD")
        .stdout.trim()


  Application =

    create: (definition) -> Application.save definition

    load: async ->

      raise "application.no-configuration" if ! yield isFile "./p42.yaml"
      branch = yield Git.getBranch()

      raise "application.no-branch" if ! branch?
      {name, domain, registry, clusters} = yield read "./p42.yaml"
      clusters ?= {}
      cluster = clusters?[branch]
      {name, domain, registry, clusters, cluster}

    save: ({name, domain, registry, clusters}) ->
      clusters ?= {}
      write "./p42.yaml", {name, domain, registry, clusters}

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

      build: async ({mixins}) ->
        application = yield Application.load()
        for name in mixins
          yield Mixins.assert name
          mixin = yield Mixins.load name
          mixin.style ?= "docker"
          directory = join ".", "run", name
          for path in yield glob "**/*.tmpl", directory
            destination = join directory, basename path, ".tmpl"
            template = yield F.read path
            content = render template, mixin
            yield F.write destination, content
          yield Decorators[mixin.style]? application, mixin

    Targets:

      add: async ({branch, cluster}) ->
        application = yield Application.load()
        application.clusters[branch] = cluster
        Application.save application

      remove: async ({branch}) ->
        application = yield Application.load()
        delete application.clusters[branch]
        Application.save application

      rename: async ({before, after}) ->
        application = yield Application.load()
        application.clusters[after] = application.clusters[before]
        delete application.clusters[before]
        Application.save application

module.exports = _exports
