msg() {

  local key="${1}" data="${2}"
  if [ -n "${data}" ]; then
    message "${messages}" "${key}" --data "${data}"
  else
    message "${messages}" "${key}"
  fi
}

err() {
  echo -n "p42: "
  1>&2 msg "${@}"
  exit 1
}
