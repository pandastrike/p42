{async} = require "fairmont"
messages = require "panda-messages"
{share} = process.env
path =  join share, "messages.yaml"
[Messages, Helpers] = []

module.exports = async (prefix) ->

  Messages ?= yield messages path

  if prefix?
    {message, abort} = Messages
    Helpers[prefix] ?=
      message: (key, data={}) -> message "#{prefix}.#{key}", data
      abort: (key, data={}) -> abort "#{prefix}.errors.#{key}", data
      usage: (key, data={}) ->
        key = (if key? then "#{prefix}.#{key}.help" else "#{prefix}.help")
        abort key, data
  else
    Messages
