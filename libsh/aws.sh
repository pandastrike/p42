include commands
include clusters

get_repo() {
  local name="${1}"
  local $(run aws.ecr.describe-repositories "name: ${1}")
  echo $repositoryid
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

get_security_group() {
  local vpc name
  local "${@}"
  local $(run aws.ec2.describe-security-groups \
    "{ name: '${name}', vpc: '${vpc}' }")
  echo $groupid
}

set_security_groups() {
  local vpc name groups
  local "${@}"

  # get the instance ID of the newly created machine
  local $(run aws.ec2.describe-instances "name: ${name}")

  local groupids
  for group in $groups; do
    groupids="${groupids} $(get_security_group vpc=${vpc} name=${group})"
  done
  run aws.ec2.modify-instance-attribute \
    "{ instanceid: '${instanceid}', groupids: '${groupids}' }"
}

get_registry_url() {
  local $(run aws.ecr.get-authorization-token)
  echo "${url}"
}

get_registry_domain() {
  get_registry_url | sed 's/^https:\/\///'
}

get_elb() {
  local cluster="${1}"
  local elb phz domain
  elb=$(aws elb describe-load-balancers \
    --load-balancer-name "${cluster}" |\
    json 'LoadBalancerDescriptions[0]')

  phz=$(json CanonicalHostedZoneNameID <<<${elb} )
  domain=$(json CanonicalHostedZoneName <<<${elb} )
  echo "elb_hosted_zone=${phz} elb_domain=${domain}"
}

get_instance() {
  local name="${1}" info id ip
  info=$(aws ec2 describe-instances \
    --filters "Name=tag-value,Values=${name}" |\
    json 'Reservations[0].Instances[0]')
  id=$(json InstanceId <<< "${aws_info}")
  ip=$(json PrivateIpAddress <<< "${aws_info}")
  echo "id=${id} ip=${ip}"
}

register_instance_with_elb() {
  local cluster instance
  local "${@}"
  # TODO: use container name and call get_instance from here?
  # echo "Adding <${container}> to ELB..."
  aws elb register-instances-with-load-balancer \
    --load-balancer-name ${cluster} \
    --instances ${id} >\
    /dev/null
}
