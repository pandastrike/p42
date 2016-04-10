{all} = require "when"
{async, empty} = require "fairmont"

_exports = do async ->

  [
    DockerHelpers
    Application
  ] = yield all [
    require "../helpers/docker"
    require "../application"
  ]

  {Mixins} = Application

  stop = (mixin) ->
    # TODO: make sure we can do it this way
    # DockerHelpers.stopContainers "#{name}-#{mixin}-"

  async ({mixins}) ->
    $P.hi()
    if empty mixins
      mixins = yield Mixins.list()

    (yield stop mixin) for mixin in mixins

module.exports = _exports
