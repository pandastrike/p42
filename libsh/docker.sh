include aws

docker_env() {
  local name
  local "${@}"
  eval $(docker-machine env ${name})
}

# TODO: what if the swarm master dies?
swarm_env() {
  local cluster
  local "${@}"
  eval $(docker-machine env --swarm ${cluster}-00)
}

docker_login() {
  eval $(aws ecr get-login --region us-east-1) > /dev/null
}

docker_run() {
  local name image options
  local "${@}"

  echo "Starting '${image}' container '${name}'..."

  docker run \
    ${option} \
    --name ${name} \
    --restart always \
    -e AWS_ACCESS_KEY_ID="$(aws configure get aws_access_key_id)" \
    -e AWS_SECRET_ACCESS_KEY="$(aws configure get aws_secret_access_key)" \
    -e AWS_DEFAULT_REGION="$(aws configure get region)" \
    -d ${image}
}

docker_inspect() {
  local container="${1}" ip port name
  info=$(docker inspect ${container} | json '[0]')
  ip=$(json 'Node.IP' <<<$info )
  port=$(json 'NetworkSettings.Ports["80/tcp"][0].HostPort' <<<$info )
  name=$(json 'Node.Name' <<<$info )
  echo "ip=${ip} port=${port} name=${name}"
}

list_containers() {
  local cluster="${1}"
  $(docker ps --filter "name=${cluster}" --format '{{ .ID }}')
}
