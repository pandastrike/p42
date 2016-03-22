YAML = require "js-yaml"
{promise} = require "when"
{resolve} = require "path"
{call, read} = require "fairmont"
prompt = require "prompt"

Interviewer =

  create: (questions) -> {questions}

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

call ->

  [path] = process.argv[2...]
  yaml = if path == "-"
    yield read process.stdin
  else
    yield read resolve path
  questions = YAML.safeLoad yaml
  interview = Interviewer.create questions
  try
    answers = yield Interviewer.start interview
    console.log YAML.safeDump answers
  catch error
    console.error error.message
    process.exit 1
