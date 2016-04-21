{basename, dirname, join} = require "path"
{mkdirp, cp, lsR, async, collect, pull, isArray, include} = require "fairmont"
{read, write} = require "panda-rw"
{lift} = require "when/node"
Interview = require "../interview"

# TODO: add this to Fairmont
# - what if source is a glob?
cpR = do ([_cp] = []) ->

  _cp = (from..., to) ->
    for _from in from
      _to = join to, (basename _from)
      cp _from, _to

  async (from, to) ->
    _from = yield lsR from
    collect pull _cp _from..., to

# TODO: why isn't this in Fairmont already
rmRF = do ([f] = []) ->
  f = lift require "rimraf"
  (directory) -> f directory

_exports = do async ->

  [
    shared
  ] = yield collect pull [
    require "../shared"
  ]

  {bye, error} = shared.loggers.status

  Commands =

    add: async ({mixin, name}) ->

      paths = shared.mixins[mixin]

      questions = yield read paths.interview
      defaults = yield read paths.template.config
      interview = yield Interview.create {questions, defaults}
      answers = yield Interview.start interview

      destination = join ".", "run", name
      yield mkdirp "0777", destination

      yield cpR (dirname paths.template.config), destination

      # overwrite config
      # - add the defaults in cases where there was no question
      include answers, defaults
      write (join destination, "config.yaml"), answers

    rm: ({mixin}) ->
      rmRF join ".", "run", mixin

  async (options) ->

    if (command = Commands[options.subcommand])?
      try
        yield command options
      catch e
        # errors expected by p42
        # have a p42 attribute
        if isArray e.p42
          bye e.p42...
        else
          # otherwise, this is unexpected, just re-throw
          error "unexpected-error"
          throw e
    else
      bye "bad-subcommand", name: options.subcommand

module.exports = _exports

# 1) load defaults from mixin directory
# 2) load interviewer with defaults
# 3) conduct interview
# 4) copy result to the run directory
