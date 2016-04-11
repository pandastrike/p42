{async} = require "fairmont"
{all} = require "when"
{read} = require "panda-rw"
raise = require "./raise"

_exports = do async ->

  [
    shared
  ] = yield all [
    require "./shared"
  ]

  definitions = yield read shared.options

  {all, any, many, optional, rule} = require "bartlett"
  {include, merge, first, second, empty, collect, map} = require "fairmont"

  # take a key and a value and return an object
  _kv = (k,v, o = {}) -> o[k] = v ; o

  # merge wrapper for use with rules
  _merge = ({value}) -> merge value...

  grammar = (r) ->
    (s) ->
      match = r(s)
      if match?
        {value, rest} = match
        if empty rest
          value
        else
          raise "bad-option", name: first rest
      else
        raise "bad-command", name: s.join ' '

  # match a set of rules in any order, but only
  # once per rule...

  set = (px...) ->

    (sx) ->

      qx = px # don't mess with the original ruleset
      rx = [] # as yet unmatched rules
      vx = [] # matched values

      # try until there are no rules left to try
      # or until there is nothing left to match
      until (empty qx) || (empty sx)
        [p, qrest...] = qx
        if (match = p(sx))?       # .... found a match
          {value, rest} = match
          vx.push value           # save the value
          sx = rest               # continue matching
          qx = [qrest..., rx...]  # reconsider unmatched rules
          rx = []                 # and emptyt the unmatched list
        else                      # ... no match yet
          qx = qrest              # move to the next rule
          rx.push p               # saving the unmatched rule

      {value: vx, rest: sx}

  # a parameter is anything that isn't a flag
  parameter = ([value, rest...]) -> {value, rest} if !value.match /^\-/

  # a word here means a specific string
  word = (w) -> ([value, rest...]) -> {value, rest} if value == w

  flag = (s) ->
    switch s.length
      when 0 then (throw new RangeError)
      when 1 then "-#{s}"
      else "--#{s}"

  normalize = (definitions) ->

    for name, d of definitions

      # with YAML refs its possible to see the same
      # definition more than once...
      if !(d.__processed)?

        d.__processed = true

        # The "key" is what we use to save the resulting value,
        # and we default it to the name (which is the property name).
        d.name = name
        d.key ?= name

        # add dashes in front of flags
        if d.flags?
          d.flags = collect map flag, d.flags
        if d.options?
          normalize d.options
        # TODO: less hacky way to generate supplementary help text
        if d.help?
          if d.default?
            d.help += " Defaults to #{d.default}."
          else if d.required || !d.optional?
            d.help += " Required."

    definitions

  build = (definitions) ->

    # As we process definitions, we're going to
    # compile a list of required options and defaults
    required = []
    defaults = {}

    # Process each definition and map the results into
    # an array of rules that we're going to place in `ax`
    px = for name, d of definitions

      # Create a base rule based on the definition type...
      p = build[d.type] d

      # Wrap it in a rule that converts the result into an
      # object with one property...
      p = do (d) ->
        # if there is a value override, use that
        if d.value?
          (rule p, -> _kv d.key, d.value)
        # otherwise just use whatever value we parsed
        else
          (rule p, ({value}) -> _kv d.key, value)

      # If this definition itself has an options definition,
      # recursively generate rules for those options,
      # and wrap that in another rule that requires both
      # the current option and the nested options to match,
      # merging the resulting objects...
      if d.options?
        p = rule (all p, (build d.options)), _merge

      # Save default values and required options...
      # Defaults take precedence.
      if d.default?
        defaults[d.key] = d.default
      else if d.required? || !d.optional?
        required.push d.key unless d.key in required

      # Return that rule, so it ends up in our rule array px
      p

    # Okay, now we have a list of rules. We'll use `set` to match
    # those in any order and then merge the resulting objects...
    q = rule (set px...), _merge

    # Now we have an object based on what we were able to parse out
    # of the options. We still need to layer in the defaults and
    # check for required options.
    do (defaults, required) ->

      (s) ->

        # If we don't match to begin with, nevermind...
        if (match = q(s))?

          {value, rest} = match

          # Layer in the defaults...
          value = merge defaults, value

          # Make sure we have all the required values...
          # The reason this works for a set is because each
          # item in the set will get marked as required
          # unless explicitly marked as optional, using the
          # same _key_ ...
          return undefined for key in required when !(value[key]?)

          # If we're still here, we have a valid result
          {value, rest}


  # helper for generating a rule for flags
  _flags = (flags) -> any (collect map word, flags)...
  _options = (flags) -> all (_flags flags), parameter

  # Generate rules based on the type attributes in the definitions
  include build,
    switch: (d) -> rule (_flags d.flags), -> true
    option: (d) -> rule (_options d.flags), ({value}) -> second value
    word: ({name}) -> word name
    list: ({subtype: {type, options}}) -> many build[type] options
    parameter: -> parameter

  parser = grammar build normalize definitions
  # parser = build normalize definitions

  parse = (args) -> parser args

  # {w} = require "fairmont"
  # $P parse w "cluster create"
  # $P parse w "cluster expand violent-aftermath -n 3"
  # $P parse w "cluster rm violent-aftermath"
  # $P parse w "cluster create"

  render = require "./template"
  messages = yield read shared.messages

  help = (name) ->
    if name?
      render messages[name].help, definitions[name]
    else
      render messages.help, definitions

  {parse, help}

module.exports = _exports
