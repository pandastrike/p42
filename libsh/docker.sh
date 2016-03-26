include aws

docker_env() {
  local name="${1}"
  run docker.machine.env "name: '${name}'"
}

swarm_env() {
  local cluster="${1}"
  # TODO: what if the swarm master dies?
  run docker.machine.swarm-env "cluster: '${cluster}-00'"
}

docker_login() { run docker.login }

docker_build() {
  local registry tag part
  local "${@}"
  local file="./run/${part}/Dockerfile"
  local qtag="${registry}/${tag}"

  run docker.build "{ tag: '${qtag}', file: '${file}'}"
}

docker_push() {
  local registry tag
  local "${@}"
  local qtag="${registry}/${tag}"

  run docker.push "tag: '${qtag}'"
}

docker_run() {
  local name tag options
  local "${@}"

  run docker.run \
    "{ options: '${options}', name: '${name}', tag: "${tag}"}"
}

docker_inspect() {
  local name="${1}" ip port name
  run docker.inspect "{ name: '${name}' }"
}

list_containers() {
  local cluster="${1}"
  run docker.ps "{ cluster: '${cluster}' }"
}
