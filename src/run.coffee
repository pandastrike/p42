{async, wrap, reduce, Method} = require "fairmont"
messages = require "panda-messages"
{yaml, json} = require "./serialize"
render = require "./template"
logger = require "./message-logger"
once = (f) -> -> k = f() ; f = wrap k ; k

init = once async ->

  {dryRun} = shared = yield do (require "./share")
  {lookup} = yield messages shared.commands

  Processors =

    dryRun: do ([f] = []) ->
      # f sets the properties of a result object
      # based on the given test values...
      f = (result, {name, test}) ->
        result[name] = test
        result
      (command) -> reduce f, {}, command.attributes

    json: (command, response) ->
      response = json response
      reduce ((result, {name, accessor}) -> data[name] = response[accessor]),
        {}, command.attributes

  Commands =

    lookup: lookup

    build: (key, data={}) ->

      {template, processor, attributes} = Commands.lookup key
      string = yaml render template, data
      {string, processor, attributes}

    run: async (key, data={}) ->

      {msg} = logger name: "commands"
      command = Commands.build key, data

      # msg key

      if dryRun
        Processors.dryRun command
      else
        response = yield sh command.string
        log "responses", command.string, response
        if response != ""
          Processors[command.processor]? command, response

module.exports = init
