{isFile, isDirectory, ls, sh} = require "fairmont"
{read, write} = require "panda-rw"

Git =

  getBranch: async ->
    (yield sh "git symbolic-ref --short -q HEAD")
    .stdout

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
      bye "application.bad-mixin" if ! yield isFile "./run/#{name}"

    list: async ->
      bye "application.nothing-to-run" if ! yield isDirectory "./run"
      yield readdir "./run"

    load: (name) -> read "./run/#{name}/config.yaml"

    build: async (mixins...) ->

      application = yield Application.load()
      mixins = if empty mixins then yield Mixins.list() else mixins

      for name in mixins
        yield Mixins.assert name
        mixin = Mixins.load name
        Decorators[mixin.style]? mixin

module.exports = Application
