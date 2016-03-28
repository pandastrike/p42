Path = require "path"
assert = require "assert"
Amen = require "amen"
{async, isDirectory} = require "fairmont"
Share = require "../src/share"
Tmp = require "../src/tmp"
# {read} = require "panda-rw"
# AWSHelpers = require "../src/helpers/aws"
# Logs = require "../src/logs"

Amen.describe "p42", (context) ->

  context.test "share", ->

    assert (yield Share).test.expectations?

  context.test "tmp", ->
    {dir, base} = Path.parse (yield Tmp.file "test.txt")
    assert.equal base, "test.txt"
    assert.equal true, (yield isDirectory dir)

  # yield read Share.expectations
  #
  # context.test "createRepository", ->
  #   Logs.clear "commands"
  #   yield AWSHelpers.createRepository "blurb9-api"
  #   actual = Logs.get "commands"
  #   expected = expectations.createRepository
  #   assert.equal actual, expected

# test_create_repo() {
#   run_test create_repo blurb9-api
# }
#
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
