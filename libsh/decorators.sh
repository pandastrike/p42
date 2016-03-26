include aws
include application
include docker

decorator() {

  local part="${1}"

  # TODO: determine the decorator from the
  # part configuration
  local name='docker'

  eval "decorator_${name} ${part}"
}

decorator_docker() {

  # TODO: reincorporate template support

  local part="${1}"
  local $(load_application)

  tag="${application}-${part}"

  docker_build \
    registry="${registry}" \
    part="${part}" \
    tag="${tag}"

  create_repo name="${tag}"

  docker_push "${tag}"

}
