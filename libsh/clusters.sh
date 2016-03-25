clusters="${config}/clusters"
mkdir -p "${clusters}"

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

  assert_cluster "${1}"

  echo "region=$(yaml get ${clusters}/${name} region) \
    zone=$(yaml get ${clusters}/${name} zone) \
    vpc=$(yaml get ${clusters}/${name} vpc) \
    subnet=$(yaml get ${clusters}/${name} subnet) \
    dns=$(yaml get ${clusters}/${name} dns)"
}

create_cluster() {

  local name="${1}"

  echo "Creating cluster '${name}'..."

  # Originally, I was going to templatize the file,
  # but I'm no longer sure that's necessary...
  yaml json write ${share}/cf/vpc.yaml > ${tmpDir}/vpc.json

  aws cloudformation create-`stack` \
    --stack-name ${name} \
    --template-body file:///${tmpDir}/vpc.json \
    > /dev/null

  while true; do
    sleep 5
    description=$(aws cloudformation describe-stacks --stack-name ${name})
    status=$(json Stacks[0].StackStatus <<<"${description}")
    if [ "$status" == "CREATE_COMPLETE" ]; then
      break
    elif [ "${status}" == "CREATE_FAILED" ]; then
      1>&2 echo "p42: cluster creation failed!"
      exit 1
    fi
  done

  az=$(json Stacks[0].Outputs[2].OutputValue <<<"${description}")

  save_cluster \
    vpc=$(json Stacks[0].Outputs[0].OutputValue <<<"${description}") \
    subnet=$(json Stacks[0].Outputs[1].OutputValue <<<"${description}") \
    region="${az%?}" \
    zone="${az: -1}" \
    dns=$(json Stacks[0].Outputs[3].OutputValue <<<"${description}") \

  echo "VPC '${name}' created."

}

remove_cluster() {
  local cluster="${1}"
  echo "Deleting AWS stack <${cluster}>..."
  aws cloudformation delete-stack --stack-name ${cluster}
  rm ${clusters}/${cluster}

}

assert_cluster() {
  local cluster="${1}"
  if [ -z "${cluster}" ]; then
    echo "No cluster name specified"
    exit 1
  else
    if [ ! -f "${clusters}/${cluster}" ]; then
      echo "Cluster <${cluster}> does not exist."
      exit 1
    fi
  fi
}
