{async} = require "fairmont"

_exports = do async ->

  {getRepository, createRepository} = yield require "./helpers/aws"
  {build, push} = yield require "./helpers/docker"

  # The beginnings of an extensible mechanism
  Decorators =

    docker: async (application, mixin) ->
      {registry} = application
      tag = "#{application.name}-#{mixin.name}"
      if !(yield getRepository tag)?
        yield createRepository tag
      yield build {registry, tag, mixin}
      push {registry, tag}

module.exports = _exports
