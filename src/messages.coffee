{join} = require "path"
YAML = require "js-yaml"
{async, read, abort, curry, binary, flip,
reduce, apply, pipe, map, identity} = require "fairmont"
render = (require "markup-js").up

{share} = process.env
messages = {}

# TODO: this belongs in Fairmont
splat = (f) -> (args...) -> f args

# reduce arguments by iterative application,
deref = curry binary flip splat reduce apply,
  (pipe (split "."),            # split the ref into an array
    (map property),             # turn that into a list property extractors
    reduce pipe, identity)      # which are then composed into a single fn

_abort = abort

module.exports = async (key) ->

  messages ?= (YAML.safeLoad (yield read (join share, "messages.yaml")))

  helpers[key] ?= do ->
    message = deref messages
    errors = deref messages.errors
    abort = (key, data={}) -> _abort (render (errors key), data)
    usage = (key) -> _abort (message (if key? then "#{key}.help" else "help")
    {message, errors, abort, usage}
