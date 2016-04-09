sprintf = require "sprintf"
M = require "markup-js"
indent = (x, s) -> (" ".repeat x) + s
M.pipes.values = (object) -> value for key, value of object
M.pipes.pluck = (objects, property) -> object[property] for object in objects
M.pipes.filter = (objects, property, value) ->
  object for object in objects when object[property] == value
M.pipes.sprintf = (string, format) -> sprintf format, string
M.pipes.hang = (s, i, w = 80) ->
  m = w - i
  [first, rest...] = s.match ///.{1,#{m}}(\s+|$)///g
  [first, ((indent i, line) for line in rest)...].join "\n"

module.exports = (template, context) -> M.up template, context
