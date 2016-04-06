{basename, join} = require "path"
{async} = require "fairmont"
{read} = require "panda-rw"
Interview = require "../interview"

module.exports = async ->

  shared = yield require "../shared"
  Application = yield require "../application"
  AWSHelpers = yield require "../helpers/aws"

  defaults =

  interview = yield Interview.create
    path: shared.interviews.init
    defaults:
      name: basename process.cwd()
      registry: AWSHelpers.getRegistryDomain()

  answers = yield Interview.start interview

  Application.create answers
