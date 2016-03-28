{basename, join} = require "path"
Appliction = require "../application"

init = async ->
  interview = Interview.create join share, "interviews", "init.yaml"
  defaults =
    name: basename Process.cwd()
    registry: AWSHelpers.getRegistryDomain()
  answers = yield interview.start defaults
  Application.create answers
