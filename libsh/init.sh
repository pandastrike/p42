root="${_P42_ROOT}"
share="${root}/lib"
share="${root}/share"
tmpDir=$(mktemp -d "${TMPDIR:-/tmp}/p42-XXXXXXXXX")
clusters="${HOME}/.config/p42/clusters"
mkdir -p "${clusters}"
