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
    target
  ] = yield all [
    require "./build"
    require "./cluster"
    require "./help"
    require "./init"
    require "./mixin"
    require "./run"
    require "./start"
    require "./stop"
    require "./target"
  ]

  {build, cluster, help, init, run, mixin, start, stop, target}
