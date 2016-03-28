{createRepository} = require "aws-helpers"
{build, push} = require "docker-helpers"

# The beginnings of an extensible mechanism
Decorators =

  docker: (application, mixin) ->
    {registry} = application
    tag = "#{application.name}-#{mixin.name}"
    createRepository tag
    yield build {registry, tag, mixin}
    push {registry, tag}

module.exports = Decorators
