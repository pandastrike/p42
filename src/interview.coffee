{promise} = require "when"
{async, read} = require "fairmont"
prompt = require "prompt"
render = require "./template"
{yaml} = require "./serialize"

Interview =

  create: async ({path, defaults}) ->
    questions: yaml render (yield read path), defaults

  start: ({questions}) ->

    prompt.message = ""
    prompt.delimiter = ":"
    prompt.start stdout: process.stderr

    promise (resolve, reject) ->
      prompt.get questions, (error, answers) ->
        if error?
          reject error
        else
          resolve answers

module.exports = Interview
