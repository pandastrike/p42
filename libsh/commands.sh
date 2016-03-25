include logging
include messages

commands_log="${logs}/commands.log"
responses_log="${logs}/responses.log"

show_commands() {
  cat "${commands_log}"
}

clear_commands() {
  > "${commands_log}"
}

show_logs() {
  cat "${results_log}"
}

process_silent() {
  :
}

process_dry_run() {

  local key="${1}" n=0 decls
  value=$(yaml get - 'test' <<< "${attribute}")

  while true ; do

    attribute=$(yaml get "${share}/commands.yaml" \
      "${key}.response.attributes.${n}")

    if [ -z "${attribute}" ]; then
      break
    fi

    name=$(yaml get - name <<< "${attribute}")
    value=$(yaml get - 'test' <<< "${attribute}")
    decls="${decls} ${name}=${value}"

    ((n++))

  done

  echo ${decls}

}

process_json() {

  local key="${1}" response="${2}" n=0 decls

  while true ; do

    attribute=$(yaml get "${share}/commands.yaml" \
      "${key}.response.attributes.${n}")

    if [ -z "${attribute}" ]; then
      break
    fi

    name=$(yaml get - name <<< "${attribute}")
    accessor=$(yaml get - accessor <<< "${attribute}")
    value=$(json "${accessor}" <<< "${response}")
    decls="${decls} ${name}=${value}"

    ((n++))

  done

  echo ${decls}

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

  echo $command >> "${commands_log}"

  if [ -n "${dry_run}" ]; then

    process_dry_run ${key}

  else

    response=$($command)

    echo $command >> "${responses_log}"
    echo $response >> "${responses_log}"

    if [ -n "${response}" ]; then

      use=$(yaml get "${share}/commands.yaml" \
        "${key}.response.use")

      if [ -n "${use}" ]; then
        process_${use} ${key} "${response}"
      else
        echo $response
      fi

    fi

  fi

}
