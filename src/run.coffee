{async, reduce, Method} = require "fairmont"
{read} = require "panda-rw"
messages = require "panda-messages"
{yaml, json} = require "./serialize"
render = require "./template"
shared = require "./share"
logger = require "./message-logger"

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

  lookup: do async ->
    {lookup} = yield messages (yield shared).commands
    lookup

  build: async (key, data={}) ->

    {template, processor, attributes} = ((yield Commands.lookup)(key))
    string = yaml render template, data
    {string, processor, attributes}

  run: async (key, data={}) ->

    {msg} = logger name: "commands"
    command = yield Commands.build key, data

    # msg key

    if (yield shared).dryRun
      Processors.dryRun command
    else
      response = yield sh command.string
      log "responses", command.string, response
      if response != ""
        Processors[command.processor]? command, response

module.exports = Commands
