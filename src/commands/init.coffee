{basename, join} = require "path"
{async} = require "fairmont"

module.exports = async ->

  Appliction = yield require "../application"

  interview = Interview.create join share, "interviews", "init.yaml"

  defaults =
    name: basename Process.cwd()
    registry: AWSHelpers.getRegistryDomain()

  answers = yield interview.start defaults

  Application.create answers
