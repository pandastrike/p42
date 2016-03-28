# black=$(tput setaf 0)
# red=$(tput setaf 1)
# green=$(tput setaf 2)
# yellow=$(tput setaf 3)
# blue=$(tput setaf 4)
# magenta=$(tput setaf 5)
# cyan=$(tput setaf 6)
# white=$(tput setaf 7)
# bold=$(tput bold)
# old=$(tput dim)
# reset=$(tput sgr0)
#
# _p() {
#   echo "$@ ${reset}"
# }
#
# _normalize() {
#   # TODO: we could actually extract the file path here,
#   # read it, and compare it to a derivable key in the
#   # expectations file, maybe the basename (which is
#   # predictable even when parameterized because the
#   # parameterization depends on the test).
#   sed -E 's/file:[\/a-zA-Z0-9_\.\-]+/file:\/\/\/****/g'
# }
#
# run_test() {
#
#   clear_commands
#   "${@}" > /dev/null
#   _diff=$(diff -B \
#     <(show_commands | _normalize) \
#     <(yaml get ${share}/test/expectations.yaml ${1}))
#
#   if [ -z "${_diff}" ]; then
#     _p ${green} ${1}: ${bold} pass
#   else
#     _p ${red} ${1}: ${bold} fail
#     _p ${red} "$_diff"
#   fi
#
# }
#
# run_tests() {
#   tests=$(declare -f | grep -E '^test_[a-zA-Z0\_]+ \(' | cut -d ' ' -f 1)
#   for test in $tests; do $test ; done
# }
