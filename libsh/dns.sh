include commands
include clusters

dns_a() {
  local cluster name ip comment
  local "${@}"
  local $(load_cluster ${cluster})

  echo "Adding DNS A record for '${name}'..."

  update_file="${tmpDir}/dns-a-${name}.json"

  cat "${clusters}/${cluster}" |\
    yaml set - machine "${name}" |\
    yaml set - ip ${ip} |\
    yaml set - comment "${comment}" |\
    yaml template - ${share}/dns/a.yaml |\
    yaml json write - > "${update_file}"

  run aws.route53.change-resource-record-sets \
    "{ dns: '${dns}', file: '${update_file}' }"

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
    --change-batch file:///${tmpDir}/dns-srv-${public}.json

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
