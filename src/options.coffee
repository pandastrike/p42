{async} = require "fairmont"
{all} = require "when"
# messages = require "panda-messages"
{read} = require "panda-rw"

_exports = do async ->

  [
    shared
  ] = yield all [
    require "./shared"
  ]

  {bye} = shared.loggers.output

  definitions = yield read shared.options

    {all, any, many, optional, rule} = require "bartlett"
    {merge, first, second, empty} = require "fairmont"

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
            throw "invalid option: #{first rest}"

    # match a set of rules in any order, but only
    # once per rule...
    set = (px...) ->
      (s) ->
        values = []
        rx = []
        until (empty px) || (empty s)
          [p, qx...] = px
          if (match = p(s))?
            {value, rest} = match
            values.push value
            s = rest
            px = [qx..., rx...]
            rx = []
          else
            px = qx
            rx.push p
        {value: values, rest: s}

    # flag parsing rules

    longFlag = (flag) -> rule (word "--#{flag}"), -> true

    shortFlag = (flag) -> rule (word "-#{flag}"), -> true

    flag = (flag) ->
      switch flag.length
        when 0 then (throw new RangeError)
        when 1 then (shortFlag flag)
        else (longFlag flag)

    flags = (ax...) -> any ((flag a) for a in ax)...

    # an option is a flag plus a parameter
    option = (ax...) ->
      rule (all (flags ax...), parameter), ({value}) -> second value

    # a parameter is anything that isn't a flag
    parameter = ([value, rest...]) -> {value, rest} if !value.match /^\-/

    # a word here means a specific string
    word = (w) -> ([value, rest...]) -> {value, rest} if value == w

    # Generate rules based on the type attributes in the definitions
    Adapters =

      toggle: (d) -> flags d.flags...

      option: (d) -> option d.flags...

      word: ({name}) -> word name

      list: ({subtype: {type, options}}) ->
        many Adapters[type] options

      parameter: -> parameter

    createRules = (definitions) ->

      # As we process definitions, we're going to
      # compile a list of required options and defaults
      required = []
      defaults = {}

      # Process each definition and map the results into
      # an array of rules that we're going to place in `ax`
      px = for name, d of definitions

        # The "key" is what we use to save the resulting value,
        # and we default it to the name (which is the property name).
        d.name = name
        d.key ?= name

        # Create a base rule based on the definition type...
        p = Adapters[d.type] d

        # Wrap it in a rule that converts the result into an
        # object with one property...
        p = do (d) -> (rule p, ({value}) -> _kv d.key, value)

        # If this definition itself has an options definition,
        # recursively generate rules for those options,
        # and wrap that in another rule that requires both
        # the current option and the nested options to match,
        # merging the resulting objects...
        if d.options?
          p = rule (all p, (createRules d.options)), _merge

        # Save default values and required options...
        # Defaults take precedence.
        if d.default?
          defaults[d.key] = d.default
        else if d.required? || !d.optional?
          required.push d.key

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
          if (match=q(s))?

            {value, rest} = match

            # Layer in the defaults...
            value = merge defaults, value

            # Make sure we have all the required values...
            return undefined for key in required when !(value[key]?)

            # If we're still here, we have a valid result
            {value, rest}

    parser = grammar createRules definitions

    parse = -> parser process.argv[2..]

  help = (name) ->

  {parse, help}

module.exports = _exports
