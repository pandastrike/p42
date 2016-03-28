stop = (mixin) ->
  # TODO: make sure we can do it this way
  DockerHelper.stopContainers "#{name}-#{mixin}-"

module.exports = (mixins...) ->
  stop mixin for mixin in mixins
