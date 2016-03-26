clusters="${config}/clusters"
mkdir -p "${clusters}"

# basically, we just want to decorate the declarations coming
# back from AWS to explicitly include the region and zone
get_stack() {
  local name=${1}
  local description=$(run aws.cloudformation.describe-stacks "name: '${name}'")
  local ${description}
  echo "name=${name} ${description} region=${az%?} zone=${az: -1}"
}

save_cluster() {
  local name vpc subnet region zone dns
  local "${@}"

  cat > "${clusters}/${name}" <<EOF
name: ${name}
vpc: ${vpc}
subnet: ${subnet}
region: ${region}
zone: ${zone}
dns: ${dns}
EOF
}

load_cluster() {

  local name="${1}"

  assert_cluster "${name}"

  echo "region=$(yaml get ${clusters}/${name} region) \
    zone=$(yaml get ${clusters}/${name} zone) \
    vpc=$(yaml get ${clusters}/${name} vpc) \
    subnet=$(yaml get ${clusters}/${name} subnet) \
    dns=$(yaml get ${clusters}/${name} dns)"
}

create_cluster() {

  local name="${1}"
  local file="${tmpDir}/vpc.json"

  yaml json write ${share}/cf/vpc.yaml > ${file}

  run aws.cloudformation.create-stack \
    "{ name: '${name}', file: '${file}' }"

  # MESSAGE: this might be a moment...
  while true; do
    if [ -z "${dry_run}" ]; then
      sleep 5
    fi
    local description="$(get_stack ${name})"
    local ${description}

    if [ "${status}" == "CREATE_COMPLETE" ]; then
      break
    elif [ "${status}" == "CREATE_FAILED" ]; then
      # MESSAGE: error
      exit 1
    fi
  done

  save_cluster ${description}
}

remove_cluster() {
  local name="${1}"
  # MESSAGE: removing cluster
  run aws.cloudformation.delete-stack "name: '${name}'"
  rm ${clusters}/${name}
}

assert_cluster() {
  local name="${1}"
  if [ -z "${name}" ]; then
    # MESSAGE: no cluster specified
    exit 1
  else
    if [ ! -f "${clusters}/${name}" ]; then
      # MESSAGE: cluster does not exist
      exit 1
    fi
  fi
}
