Commands =

  add: ->

  remove: ->

  rename: ->


module.exports = (subcomand, argv...) ->

  procesor = CLI.Processor.create Commands
  processor subcommand, argv...
