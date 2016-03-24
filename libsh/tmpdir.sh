if [ -z "${tmpDir}" ]; then
  tmpDir=$(mktemp -d "${TMPDIR:-/tmp}p42-XXXXXXXXX")
  trap "rm -rf ${tmpDir}" EXIT
fi
