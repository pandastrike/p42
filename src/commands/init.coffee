{basename, join} = require "path"
{async} = require "fairmont"
{read} = require "panda-rw"
Interview = require "../interview"

# TODO: if a p42.yaml file already exists, use it
# as the default instead

module.exports = async ->

  shared = yield require "../shared"
  Application = yield require "../application"
  AWSHelpers = yield require "../helpers/aws"

  {info} = shared.loggers.status

  info "init.determining-registry"
  registry = yield AWSHelpers.getRegistryDomain()

  name = basename process.cwd()

  interview = yield Interview.create
    path: shared.interviews.init
    defaults: {name, registry}

  try
    answers = yield Interview.start interview
  # Node's read fn throws an exception on SIGINT
  # TODO: is there a better way to do deal with this?
  catch e
    if e.message == "canceled"
      process.exit 1
    else
      throw e

  Application.create answers
