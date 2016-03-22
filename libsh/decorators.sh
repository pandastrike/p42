decorator() {
  part="${1}"

  # TODO: determine the decorator from the
  # part configuration
  name='docker'

  eval "decorator_${name} part=${part}"
}

decorator_docker() {

  local part label
  local "${@}"

  label=$name-$part
  echo "Building ${label} component..."

  # instantiate mixin templates, if any
  yaml="./run/${part}/config.yaml"
  templates=$(ls ./run/${part}/*.template 2> /dev/null)
  for template in $templates; do
    output=${template%.template}
    cat > $output <<EOF
# WARNING:
# This file was automatically generated!
#
# To make changes, edit
#   $(basename $template)
# instead.

$(yaml template $yaml $template)
EOF
  done

  docker build \
    -t "${registry}/${label}" \
    -f "run/${part}/Dockerfile" \
    .

  create_repo name="${label}"

  echo "Pushing $label component..."
  docker push "${registry}/${label}"

}
