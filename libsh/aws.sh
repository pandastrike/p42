create_repo() {
  local name
  local "${@}"
  if [ ! "$(aws ecr describe-repositories \
    --repository-name ${name} \
    --region us-east-1)" ]; then
    echo "Creating repository '${name}'..."
    aws ecr create-repository \
      --repository-name "${name}" \
      --region us-east-1 \
      > /dev/null
    policy=$(yaml json write "${share}/ecr/policy.yaml")
    aws ecr set-repository-policy \
      --repository-name "${name}" \
      --region us-east-1 \
      --policy-text "${policy}"
  fi
}

get_security_group() {
  local vpc name
  local "${@}"
  aws ec2 describe-security-groups \
    --filters \
      "Name=vpc-id,Values=${vpc}" \
      "Name=group-name,Values=${name}" |\
    json SecurityGroups[0].GroupId
}

set_security_groups() {
  local vpc name groups
  local "${@}"

  # get the instance ID of the newly created machine
  id=$(aws ec2 describe-instances \
    --filters "Name=tag-value,Values=${name}" |\
    json 'Reservations[0].Instances[0].InstanceId')

  local ids
  for group in $groups; do
    ids="${ids} $(get_security_group vpc=${vpc} name=${group})"
  done

  aws ec2 modify-instance-attribute \
    --instance-id ${id} \
    --groups ${ids}
}

get_registry_url() {
  aws ecr get-authorization-token \
    --region us-east-1 |\
    json authorizationData[0].proxyEndpoint
}

get_registry_domain() {
  get_registry_url | sed 's/^https:\/\///'
}

dns_a() {


  local name ip comment
  local "${@}"

  echo "Adding DNS A record for '${name}'..."

  cat "${clusters}/${cluster}" |\
    yaml set - machine "${name}" |\
    yaml set - ip ${ip} |\
    yaml set - comment "${comment}" |\
    yaml template - $_P42_ROOT/share/dns/a.yaml |\
    yaml json write - > "${tmpDir}/dns-a-${name}.json"

  aws route53 change-resource-record-sets \
    --hosted-zone-id ${dns} \
    --change-batch file:///${tmpDir}/dns-a-${name}.json \
    > /dev/null

}

# TODO: handle entry with no subdomain
dns_alias() {

  local cluster subdomain domain comment
  local "${@}"

  msg 'dns.elb-alias' "subdomain: ${subdomain}"

  local "$(get_elb ${cluster})"
  local id=$(aws route53 list-hosted-zones-by-name \
    --dns-name ${domain} \
    --max-items 1 |\
    json HostedZones[0].Id)

  cat "${clusters}/${cluster}" |\
    yaml set - domain "${subdomain}.${domain}" |\
    yaml set - name "${elb_domain}" |\
    yaml set - zone "${elb_hosted_zone}" |\
    yaml set - comment "${comment}" |\
    yaml template - $_P42_ROOT/share/dns/alias.yaml |\
    yaml json write - > "${tmpDir}/dns-alias-${subdomain}.json"

  aws route53 change-resource-record-sets \
    --hosted-zone-id "${id}" \
    --change-batch file:///${tmpDir}/dns-alias-${subdomain}.json \
    > /dev/null

  # Temporary hack--we assume www is also the apex record,
  # so we add a second alias for apex.
  if [ "${sudomain}" = "www" ]; then
    dns_alias \
      subdomain="" \
      domain="${domain}" \
      comment="${comment}"
  fi
}

dns_srv() {
  local cluster protocol public targets comment
  local "${@}"

  echo -n "Adding DNS SRV '${protocol}' record "
  if [ -n "${public}" ]; then
    echo "  for '${public}'..."
  else
    echo "  for zone apex..."
  fi

  cat "${clusters}/${cluster}" |\
    yaml set - protocol "${protocol}" |\
    yaml set - public "${public}" |\
    yaml set - comment "${comment}" |\
    (cat && echo 'targets: ' && \
      printf -- '-  host: %s\n   port: %s\n' $targets) |\
    yaml template - $_P42_ROOT/share/dns/srv.yaml |\
    yaml json write - > "${tmpDir}/dns-srv-${public}.json"

  aws route53 change-resource-record-sets \
    --hosted-zone-id ${dns} \
    --change-batch file:///${tmpDir}/dns-srv-${public}.json \
    > /dev/null

  # Temporary hack--we assume www is also the apex record,
  # so we add a second SRV for the empty value, ex: _._http.
  if [ "${public}" = "www" ]; then
    dns_srv \
      protocol="${protocol}" \
      public="" \
      private="${private}" \
      port="${port}" \
      comment="${comment}"
  fi

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
