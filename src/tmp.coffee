{join} = require "path"
{async, shell, rmDir, mkdirp, exists} = require "fairmont"

# TODO: check for error
# TODO: use run instead? ex: run "mktemp"
sh = async (command) ->
  (yield shell command)
  .stdout.trim()

counter = 0
Tmp =

  dir: do async ->
    (yield sh 'mktemp -d "${TMPDIR:-/tmp}p42-XXXXXXXXX"')

  file: async (name) ->
    name ?= "file-#{counter++}"
    path = yield Tmp.dir
    yield mkdirp path
    join path, name

process.on "exit", ->
  path = yield Tmp.dir
  rmDir path if yield exists path

module.exports = Tmp
