if [[ ! -o interactive ]]; then
    return
fi

compctl -K _p42 p42

_p42() {
  local word words completions
  read -cA words
  word="${words[2]}"

  if [ "${#words}" -eq 2 ]; then
    completions="$(p42 commands)"
  else
    completions="$(p42 completions "${word}")"
  fi

  reply=("${(ps:\n:)completions}")
}
