create_instance() {
  local name region zone vpc subnet options
  local "${@}"
  docker-machine create ${name} \
    --driver amazonec2 \
    --amazonec2-region ${region} \
    --amazonec2-vpc-id ${vpc} \
    --amazonec2-subnet-id ${subnet} \
    --amazonec2-zone ${zone} \
    ${options}
}

create_swarm_node() {

  local master cluster
  local "${@}"
  local "$(load-cluster ${cluster})"

  create_instance \
    name="$(find_available_name ${cluster})" \
    region=${region} \
    zone=${zone} \
    vpc=${vpc} \
    subnet=${subnet} \
    options="--swarm \
      ${master+--swarm-master} \
      --swarm-discovery nodes://10.0.[0:255].[0:255]:2375"

  # We need to add the VPC default SG
  set_security_groups \
    vpc="${vpc}" \
    name="${name}" \
    groups="default docker-machine"
}

find_available_name() {
  local cluster="${1}"
  local candidates=$(printf '%s\n' $(echo ${cluster}-{0..9}{0..9}))
  local taken=$(list-nodes ${cluster})
  # return the first element from candidates list that
  # isn't in the taken list...
  comm -23 <(echo "${candidates}") <(echo "${taken}") | head -n 1
}

list_swarm_nodes() {
  docker-machine ls \
    --format '{{ .Name }}' \
    --filter "name=${1}"
}

remove_swarm_nodes() {
  local cluster="${1}"
  echo "Removing Swarm nodes for cluster <${cluster}>"
  local machines=$(list_swarm_nodes ${cluster})
  docker-machine stop $machines
  docker-machine rm $machines
}
