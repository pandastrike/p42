{identity} = require "fairmont"
sprintf = require "sprintf"
H = require "handlebars"
S = require "swag"
S.registerHelpers H
join = (d, array) -> array.join d

block = (f) ->
  (args..., options) ->
    if options.fn?
      join "", f args..., options.fn
    else
      f args..., identity

H.registerHelper

  values: block (object, f) -> f value for key, value of object

  filter: block (property, value, objects, f) ->
    (f object) for object in objects when object[property] == value

  pluck: block (property, objects, f) ->
    (f object[property]) for object in objects

  join: (delimiter, array) -> join delimiter, array

  sprintf: (format, string) -> sprintf format, string

  hang: do ->
    indent = (x, s) -> (" ".repeat x) + s
    (i, w, s) ->
      m = w - i
      [first, rest...] = s.match ///.{1,#{m}}(\s+|$)///g
      [first, ((indent i, line) for line in rest)...].join "\n"

module.exports = (template, context) -> 
  (H.compile template, noEscape: true)(context)
