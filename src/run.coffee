{reduce} = require "fairmont"
{read} = require "panda-rw"
yaml = ...
json = ...

render = (template, context) -> # js-markup

Processors =

  dryRun: (command) ->
    reduce ((result, {name, test}) -> data[name] = test),
      {}, command.attributes

  json: (command, response) ->
    response = json response
    reduce ((result, {name, accessor}) -> data[name] = response[accessor]),
      {}, command.attributes

Commands =

  path: "#{share}/commands.yaml"

  init: async -> Commands.dictionary = yield read Commands.path

  build: (key, data={}) ->

    {template, processor, attributes} = Commands.dictionary[key]
    string = yaml render template, data
    {string, processor, attributes}

  run: async (key, data={}) ->

    command = build key, data
    log "commands", command.string

    if config.dryRun
      Processors.dryRun command
    else
      response = yield sh command.string
      log "responses", command.string, response
      if response != ""
        Processors[command.processor]? command, response
