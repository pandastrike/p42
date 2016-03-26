assert_application() {
  if [ ! -e './p42.yaml' ]; then
    # MESSAGE: missing p42 YAML file
    exit 1
  fi
}

get_branch() { git symbolic-ref --short -q HEAD }

load_application() {
  assert_application
  branch=$(get_branch)
  if [ -z ${branch} ]; then
    # MESSAGE: oh dear
    exit 1
  fi
  cluster=$(yaml get './p42.yaml' clusters.${branch})
  if [ -z ${cluster} ]; then
    # MESSAGE: oh dear
    exit 1
  fi
  echo "application=$(yaml get './p42.yaml' name) \
    domain=$(yaml get './p42.yaml' domain) \
    registry=$(yaml get './p42.yaml' registry) \
    cluster=${cluster}"
}

assert_parts() {
  if [ ! -d './run' ]; then
    # MESSAGE: nothing to run
    exit 1
  fi
  if [ -n "${@}" ]; then
    for part in ${@}; do assert_part "${part}" ; done
  fi
}

assert_part() {
  if [ ! -d "./run/${1}" ]; then
    # MESSAGE: part doesn't exist
    exit 1
  fi
}

get_parts() {
  assert_parts
  ls ./run
}
