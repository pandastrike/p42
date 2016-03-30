{async, wrap, reduce, Method} = require "fairmont"
messages = require "panda-messages"
{yaml, json} = require "./serialize"
render = require "./template"
logger = require "./message-logger"
once = (f) -> -> k = f() ; f = wrap k ; k
unquote = (s) ->
  s
  .replace /\s+/g, ' '
  .trim()


init = once async ->

  shared = yield do (require "./share")
  {lookup} = yield messages shared.commands

  Processors =

    dryRun: do ([f] = []) ->
      # f sets the properties of a result object
      # based on the given test values...
      f = (result, {name, test}) ->
        result[name] = test
        result
      (command) ->
        reduce f, {}, command.attributes if command.attributes?

    json: (command, response) ->
      response = json response
      reduce ((result, {name, accessor}) -> data[name] = response[accessor]),
        {}, command.attributes

  Commands =

    lookup: lookup

    build: (key, data={}) ->

      {template, processor, attributes} = Commands.lookup key
      string = unquote render template, data
      {string, processor, attributes}

    run: async (key, data={}) ->

      {log} = yield logger "commands"
      command = Commands.build key, data


      if shared.dryRun
        yield log.info command.string
        Processors.dryRun command
      else
        log.info command.string
        response = yield sh command.string
        # log command.string, response
        if response != ""
          Processors[command.processor]? command, response

module.exports = init
