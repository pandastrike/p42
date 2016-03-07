{join} = require "path"
YAML = require "js-yaml"
{call, read} = require "fairmont"

# This function selects and returns a random element from an input array.
pluck = (list) ->
  {random, round} = Math
  index = round random() * (list.length - 1)
  return list[index]

# Get the path to the words file
path = join process.env._P42_ROOT, "share", "words.yaml"

# Generate a name from our list of adjectives and nouns.
call ->
  {adjectives, nouns} = YAML.safeLoad yield read path
  console.log "#{pluck adjectives}-#{pluck nouns}"
