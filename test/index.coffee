Path = require "path"
assert = require "assert"
{promise} = require "when"
Amen = require "amen"
{async, isDirectory, isWriteStream, sleep} = require "fairmont"
{read} = require "panda-rw"
{EventEmitter} = require "events"

# This ensures that when we're logging the commands for test A,
# we don't interfere with the commands for test B.
synchronize = do (waiting=[]) ->

  # Main run loop. We wait one second before we starting processing
  # functions in the wait queue to ensure the tests are all queued.
  do async ->
    yield sleep 1000
    yield g() while g = waiting.shift()

  # Queuing function defined as 'synchronize'. We return a promise
  # the test can yield on, but all we do is a queue a wrapper fn.
  # The wrapper propagates the result back here from the run loop,
  # resolving the promise the test code is waiting on.
  (f) ->
    promise (resolve, reject) ->
      waiting.push async ->
        try
          # Important to yield here so that the run loop will wait
          # until f completes before running the next fn.
          resolve yield f()
        catch error
          reject error

command = (name, context, f) ->
  context.test name, ->
    yield synchronize async ->
      shared = yield do (require "../src/share")
      shared.dryRun = true
      logger = require "../src/message-logger"
      {msg, log} = yield logger "commands"
      yield log.clear()
      yield f()
      actual = yield log.read()
      expectations = yield read shared.test.expectations
      expected = expectations[name]
      assert.equal actual, expected

Amen.describe "p42", (context) ->

  context.test "share", ->
    shared = yield do (require "../src/share")
    assert shared.test.expectations?

  context.test "tmp", ->
    Tmp = require "../src/tmp"
    {dir, base} = Path.parse (yield Tmp.file "test.txt")
    assert.equal base, "test.txt"
    assert.equal true, (yield isDirectory dir)

  context.test "logger", ->
    Logger = require "../src/logger"
    yield Logger.info "fubar", "this is a test"
    yield Logger.info "fubar", "this is not a test"
    content = yield Logger.read "fubar"
    assert.equal content, "this is a test\nthis is not a test\n"

  context.test "message logger", ->
    logger = require "../src/message-logger"
    {msg, log} = yield logger "test"
    msg "fubar", name: "baz"
    log.error "oops"
    content = yield log.read "test"
    assert.equal content, "this is a test baz\noops\n"

  context.test "shell runner", ->
    yield synchronize async ->
      shared = yield do (require "../src/share")
      shared.dryRun = true
      {run} = yield do (require "../src/run")
      {zoneId} = yield run "aws.route53.list-hosted-zones-by-name",
        domain: "fubar.com"
      assert.equal zoneId, "test-dns-00"

  command "getRepository", context, async ->
    {getRepository} = yield do (require "../src/helpers/aws")
    {repositoryId} = yield getRepository "blurb9-api"
    assert.equal repositoryId, "test-repo-00"

  command "createRepository", context, async ->
    {createRepository} = yield do (require "../src/helpers/aws")
    yield createRepository "blurb9-api"


# test_set_security_groups() {
#   run_test set_security_groups \
#     vpc=test-vpc-00 \
#     name=test-instance-00 \
#     groups='default docker-machine'
# }
#
# test_get_registry_domain() {
#   run_test get_registry_domain
# }
#
# test_get_elb() {
#   run_test get_elb 'violent-aftermath'
# }
#
# test_register_with_elb() {
#   run_test register_with_elb \
#     instance_id='test-instance-00' \
#     cluster='vodka-martini'
# }
#
# _test_create_cluster() {
#   run_test create_cluster preventative-malpractice
# }
#
# _test_remove_cluster() {
#   run_test remove_cluster preventative-malpractice
# }
#
# test_cluster_suite() {
#   _test_create_cluster
#   # TODO: we need a way to pass/fail on this assert
#   assert_cluster preventative-malpractice
#   _test_remove_cluster
# }
#
# test_dns_alias() {
#   run_test dns_alias \
#     cluster='violent-aftermath' \
#     subdomain='foo' \
#     domain='bar.com' \
#     comment='this is a test'
# }
#
# test_dns_srv() {
#   run_test dns_srv \
#     cluster='violent-aftermath' \
#     protocol='http' \
#     public='www' \
#     private='www-00' \
#     port='12345' \
#     comment='this is a test'
# }
#
# # yamlize() {
# #   local "${@}"
# #   echo $comment
# # }
# #
# # test_yamlize() {
# #   yamlize \
# #     cluster='violent-aftermath' \
# #     protocol='http' \
# #     public='www' \
# #     private='www-00' \
# #     port='12345' \
# #     comment='this is a test'
# # }
# #
# declare test $(options 'test' ${@})
#
# dry_run=true
# clusters="${share}/test/clusters"
#
# if [ -n "${test}" ]; then
#   "test_${test}"
# else
#   run_tests
# fi
