include aws
include commands
include clusters

dns_a() {

  local cluster name ip comment
  local "${@}"
  local $(load_cluster ${cluster})

  file="${tmpDir}/dns-a-${name}.json"

  cat "${clusters}/${cluster}" |\
    yaml set - machine "${name}" |\
    yaml set - ip ${ip} |\
    yaml set - comment "${comment}" |\
    yaml template - ${share}/dns/a.yaml |\
    yaml json write - > "${update_file}"

  run aws.route53.change-resource-record-sets \
    "{ zone_id: '${dns}', file: '${file}' }"

}

# TODO: handle entry with no subdomain
dns_alias() {

  local cluster subdomain domain comment
  local "${@}"

  local "$(get_elb ${cluster})"
  local "$(run aws.route53.list-hosted-zones-by-name "domain: '${domain}'")"


  cat "${clusters}/${cluster}" |\
    yaml set - domain "${subdomain}.${domain}" |\
    yaml set - name "${elb_domain}" |\
    yaml set - zone "${elb_zone_id}" |\
    yaml set - comment "${comment}" |\
    yaml template - "${share}/dns/alias.yaml" |\
    yaml json write - > "${file}"

  run aws.route53.change-resource-record-sets \
    "{ zone_id: '${domain_zone_id}', file: '${file}' }"

  # Temporary hack--we assume www is also the apex record,
  # so we add a second alias for apex.
  if [ "${sudomain}" = "www" ]; then
    dns_alias \
      cluster="${cluster}" \
      subdomain="" \
      domain="${domain}" \
      comment="${comment}"
  fi
}

dns_srv() {
  local cluster protocol public targets comment
  local "${@}"

  # MESSAGE: adding SRV record for
  if [ -n "${public}" ]; then
    # MESSAGE for
    :
  else
    # MESSAGE for zone apex
    :
  fi

  local $(load_cluster ${cluster})

  local file="${tmpDir}/dns-srv-${public}.json"

  cat "${clusters}/${cluster}" |\
    yaml set - protocol "${protocol}" |\
    yaml set - public "${public}" |\
    yaml set - comment "${comment}" |\
    (cat && echo 'targets: ' && \
      printf -- '-  host: %s\n   port: %s\n' $targets) |\
    yaml template - "${share}/dns/srv.yaml" |\
    yaml json write - > "${file}"

  run aws.route53.change-resource-record-sets \
    "{ zone_id: '${dns}', file: '${file}' }"

  # Temporary hack--we assume www is also the apex record,
  # so we add a second SRV for the empty value, ex: _._http.
  if [ "${public}" = "www" ]; then
    dns_srv \
      cluster="${cluster}" \
      protocol="${protocol}" \
      public="" \
      private="${private}" \
      port="${port}" \
      comment="${comment}"
  fi
}
