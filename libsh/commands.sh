include logging

commands_log="${logs}/commands.log"

show_commands() {
  cat "${commands_log}"
}

run() {

  local key="${1}" data="${2}"

  if [ -n "${data}" ]; then

    command=$(message "${share}/commands.yaml" \
      "${key}.template" \
      --data "${data}")
  else

    command=$(message "${share}/commands.yaml" \
      "${key}.template")

  fi

  if [ -z "${dry_run}" ]; then

    response=$($command)

  fi

  echo $command >> "${commands_log}"

  n=0
  decls=""

  while true ; do

    attribute=$(yaml get "${share}/commands.yaml" \
      "${key}.response.attributes.${n}")

    if [ -z "${attribute}" ]; then
      break
    fi

    name=$(yaml get - name <<< "${attribute}")

    if [ -z "${dry_run}" ]; then

      accessor=$(yaml get - accessor <<< "${attribute}")
      value=$(json "${accessor}" <<< "${response}")

    else

      value=$(yaml get - 'test' <<< "${attribute}")

    fi

    decls="${decls} ${name}=${value}"

    ((n++))

  done

  echo ${decls}

}
