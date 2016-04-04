{async} = require "fairmont"
{all} = require "when"

module.exports = do async ->

  [
    build
    cluster
    init
    mixin
    run
    start
    stop
  ] = yield all [
    require "./build"
    require "./cluster"
    require "./init"
    # require "./mixin"
    require "./run"
    require "./start"
    require "./stop"
  ]

  {build, cluster, init, run, mixin, start, stop}
