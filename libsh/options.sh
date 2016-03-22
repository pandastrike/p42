options() {
  local command="${1}"
  # TODO: this construct loses quoted arguments :/
  local -a options="(${@:2})"
  local option def name type value decls
  decls=$(yaml get "${share}/options.yaml ${command}.defaults")
  while [ -n "${options}" ]; do
    option=${options[@]:0:1}
    options=(${options[@]:1})
    if [[ "${option}" =~ ^-+ ]]; then
      def=$(yaml get "${share}/options.yaml ${command}.${option}")
      if [ -n "${def}" ]; then
        name=$(yaml get - name <<<"$def")
        type=$(yaml get - type <<<"$def")
        if [ "${type}" == "boolean" ]; then
          decls="${decls} ${name}=true"
        else
          value=${options[@]:0:1}
          options=(${options[@]:1})
          decls="${decls} ${name}=${value}"
        fi
      else
        echo "Invalid option: ${option}"
        exit 1
      fi
    else
      def=$(yaml get "${share}/options.yaml ${command}.no-flag")
      if [ -n "${def}" ]; then
        name=$(yaml get - name <<<"$def")
        type=$(yaml get - type <<<"$def")
        decls="${decls} ${name}=${option}"
      fi
    fi
  done
  echo ${decls}
}
