share="${_P42_ROOT}/share"
app="./p42.yaml"

if [ ! -e ./p42.yaml ]; then
  echo p42: missing p42.yaml file
  echo p42: try running: p42 init
  exit -1
fi

branch=$(git symbolic-ref --short -q HEAD)
if [ -z ${branch} ]; then
  >&2 echo "p42: Not currently in a branch"
  exit -1
fi

name=$(yaml get "${app}" name)
repo=$(yaml get "${app}" repo)
registry=$(yaml get "${app}" registry)
cluster=$(yaml get "${app}" clusters.${branch})

if [ -z ${cluster} ]; then
  >&2 echo "p42: No target found for branch ${branch}"
  exit -1
fi

clusters="${HOME}/.config/p42/clusters"
mkdir -p "${clusters}"

region=$(yaml get ${clusters}/${cluster} region)
zone=$(yaml get ${clusters}/${cluster} zone)
vpc=$(yaml get ${clusters}/${cluster} vpc)
subnet=$(yaml get ${clusters}/${cluster} subnet)
dns=$(yaml get ${clusters}/${cluster} dns)

tmpDir=$(mktemp -d "${TMPDIR:-/tmp}/p42.XXXXXXXXX")
