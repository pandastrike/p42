{async} = require "fairmont"
{all} = require "when"

module.exports = do async ->

  [
    build
    cluster
    help
    init
    mixin
    run
    start
    stop
  ] = yield all [
    require "./build"
    require "./cluster"
    require "./help"
    require "./init"
    require "./mixin"
    require "./run"
    require "./start"
    require "./stop"
  ]

  {build, cluster, help, init, run, mixin, start, stop}
