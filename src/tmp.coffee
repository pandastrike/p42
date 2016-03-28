{join} = require "path"
{async, shell, rmDir, mkdirp} = require "fairmont"

sh = async (command) ->
  (yield shell command)
  .stdout.trim()

Tmp =

  dir: do async ->
    (yield sh 'mktemp -d "${TMPDIR:-/tmp}p42-XXXXXXXXX"')

  file: async (name) ->
    path = yield Tmp.dir
    yield mkdirp path
    join path, name

process.on "exit", -> rmDir (yield Tmp.dir)

module.exports = Tmp
