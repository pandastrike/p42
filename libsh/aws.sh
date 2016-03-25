include commands
include clusters

get_instance() {
  local name="${1}"
  run aws.ec2.describe-instances "name: '${name}'"
}

get_security_group() {
  local vpc name
  local "${@}"
  local $(run aws.ec2.describe-security-groups \
    "{ name: '${name}', vpc: '${vpc}' }")
  echo $group_id
}

set_security_groups() {
  local vpc name groups
  local "${@}"

  local $(get_instance "${name}")

  local group_ids
  for group in $groups; do
    group_ids="${group_ids} $(get_security_group vpc=${vpc} name=${group})"
  done

  run aws.ec2.modify-instance-attribute \
    "{ instance_id: '${instance_id}', group_ids: '${group_ids}' }"
}

get_elb() {
  run aws.elb.describe-load-balancers \
    "{ cluster: '${1}' }"
}

register_with_elb() {
  local cluster instance_id
  local "${@}"
  # TODO: use container name and call get_instance from here?
  # echo "Adding <${container}> to ELB..."
  run aws.elb.register-instances-with-load-balancer \
    "{ cluster: '${cluster}', instance_id: '${instance_id}' }"
}

get_registry_url() {
  local $(run aws.ecr.get-authorization-token)
  echo "${url}"
}

get_registry_domain() {
  get_registry_url | sed 's/^https:\/\///'
}

get_repo() {
  local name="${1}"
  local $(run aws.ecr.describe-repositories "name: ${1}")
  echo $repository_id
}

create_repo() {
  local name="${1}"
  if [ -z "$(get_repo ${name})" ]; then
    run aws.ecr.create-repository "name: ${name}"
    policy="$(yaml json write ${share}/ecr/policy.yaml)"
    run aws.ecr.set-repository-policy \
      "{name: '${name}', policy: '${policy}'}"
  fi
}
