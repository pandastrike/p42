{async} = require "fairmont"
dashdash = require "dashdash"
{all} = require "when"
{read} = require "panda-rw"

_exports = do async ->

  [
    shared
  ] = yield all [
    require "./shared"
  ]

  {bye} = shared.loggers.output

  definitions = yield read shared.options

  Options =

    createParser: (name) ->

      parser = dashdash.createParser
        allowUnknown: true
        options: definitions[name]

    parse: (name, args) ->

      parser = Options.createParser name

      options = parser.parse args

      # TODO: defer to each command handler?
      if options.help
        bye "main.help", options: parser.help()
      else
        options

    help: (name) ->

      bye "#{name}.help", options: (Options.createParser name).help()


module.exports = _exports
