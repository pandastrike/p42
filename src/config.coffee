#!/usr/bin/env bash
set -e

resolve_link() {
  $(type -p greadlink readlink | head -1) "$1"
}

abs_dirname() {
  local cwd="$(pwd)"
  local path="$1"

  while [ -n "$path" ]; do
    cd "${path%/*}"
    local name="${path##*/}"
    path="$(resolve_link "$name" || true)"
  done

  pwd
  cd "$cwd"
}

libexec_path="$(abs_dirname "$0")"
export _P42_ROOT="$(abs_dirname "$libexec_path")"
export PATH="${libexec_path}:$PATH"
export root="${_P42_ROOT}"
export lib="${root}/libsh"
export share="${root}/share"
export messages="${share}/messages.yaml"
export mixins="${share}/mixins"
export config="${HOME}/.config/p42"
mkdir -p "${config}"

include() {
  if [[ ! "${included}" =~ "${1}" ]]; then
    source "${lib}/${1}.sh"
    included="${included} ${1}"
  fi
}

export -f include

command="$1"
case "$command" in
"" | "-h" | "--help" )
  exec p42-help
  ;;
* )
  command_path="$(command -v "p42-$command" || true)"
  if [ ! -x "$command_path" ]; then
    echo "p42: no such command \`$command'" >&2
    exit 1
  fi

  shift
  exec "$command_path" "$@"
  ;;
esac
