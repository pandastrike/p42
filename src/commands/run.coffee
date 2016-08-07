{all} = require "when"
{async} = require "fairmont"
_exports = do async ->

  [
    build
    start
  ] = yield all [
    require "./build"
    require "./start"
  ]

  async ->
    yield build arguments...
    start arguments...

module.exports = _exports
