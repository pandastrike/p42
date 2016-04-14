{async, reduce, Method} = require "fairmont"
messages = require "panda-messages"
{yaml, json} = require "./serialize"
render = require "./template"
createShell = require "./sh"

unquote = (s) ->
  s
  .replace /\s+/g, ' '
  .trim()

_exports = do async ->

  shared = yield require "./shared"
  {lookup} = yield messages shared.commands
  C = shared.loggers.command
  S = shared.loggers.status

  # TODO: elegant way to access logger streams?
  if !shared.settings.dryRun
    shell = createShell stderr: S._self.loggers.stderr.stream
    sh = shell.run
    process.on "exit", -> shell.close()

  build = (key, data={}) ->
    {template, processor, attributes, test} = lookup key
    string = unquote render template, data
    {string, processor, attributes, test}

  Processors =

    line: (command, response) -> response.split "\n"

    # TODO: Object reference parsing should be in Fairmont
    # or something...
    json: (command, response) ->
      data = json response
      result = {}
      for {name, accessor} in command.attributes
        current = data
        for key in accessor.split(".")
          current = current[key]
          break if ! current?
        result[name] = current
      result

  run = async (key, data={}) ->

    command = build key, data

    if shared.settings.dryRun
      yield C.info command.string
      command.test
    else
      C.info command.string
      response = yield sh command.string
      S._debug command.string
      if response != ""
        S._debug response
        Processors[command.processor]? command, response

module.exports = _exports
