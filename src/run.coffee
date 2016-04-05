{async, reduce, Method} = require "fairmont"
messages = require "panda-messages"
{yaml, json} = require "./serialize"
render = require "./template"

unquote = (s) ->
  s
  .replace /\s+/g, ' '
  .trim()

_exports = do async ->

  shared = yield require "./shared"
  {lookup} = yield messages shared.commands
  C = shared.loggers.dryRun
  O = shared.loggers.output

  build = (key, data={}) ->
    {template, processor, attributes, test} = lookup key
    string = unquote render template, data
    {string, processor, attributes, test}

  Processors =

    line: (command, reponse) ->
      # TODO: implement line processor

    json: (command, response) ->
      response = json response
      reduce ((result, {name, accessor}) -> data[name] = response[accessor]),
        {}, command.attributes

  run = async (key, data={}) ->

    command = build key, data
    if shared.dryRun
      yield C.info command.string
      command.test
    else
      C.info command.string
      response = yield sh command.string
      O._info command.string
      if response != ""
        O._info response
        Processors[command.processor]? command, response

module.exports = _exports
