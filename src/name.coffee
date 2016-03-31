{read} = require "panda-rw"
{async, pluck} = require "fairmont"

[adjectives, nouns] = []

_exports = do async ->

  shared = yield require "./shared"
  {adjectives, nouns} = yield read shared.words

  Name =

    # Generate a name from our list of adjectives and nouns.
    generate: ->
      if shared.dryRun
        "violent-aftermath"
      else
        "#{pluck adjectives}-#{pluck nouns}"

module.exports = _exports
