{async} = require "fairmont"
messages = require "panda-messages"
{share} = process.env
path =  join share, "messages.yaml"
[Messages, Helpers] = []

module.exports = async (prefix) ->

  Messages ?= yield messages path

  if prefix?
    Helpers[prefix] ?=
      message: (key, data={}) -> Messages.message "#{prefix}.#{key}", data
      abort: (key, data={}) -> Messages.abort "#{prefix}.errors.#{key}", data
      usage: (key, data={}) ->
        if key?
          Messages.abort "#{prefix}.#{key}.help", data
        else
          Messages.abort "#{prefix}.help", data
  else
    Messages
