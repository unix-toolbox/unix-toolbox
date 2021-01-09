#!/usr/bin/env bash


# input: <name-of-array-variable> <value-to-find>
# return: 0 (found) or 1 (not found)
utb_util_array_contains() {
  declare -n array_ref="$1"
  local needle="$2"
  local item
  for item in "${array_ref[@]}"; do
    [[ "$item" == "$needle" ]] && return 0
  done
  return 1
}


# input: <name-of-array-variable> <value-to-add>
utb_util_array_add() {
  declare -n array_ref="$1"
  local value="$2"
  array_ref+=("$value")
}


# remove all occurrences of <value-to-remove> from the array
# input: <name-of-array-variable> <value-to-remove>
utb_util_array_remove() {
  declare -n array_ref="$1"
  local value="$2"
  local i tempAry=()
  for i in "${!array_ref[@]}"; do
    local current="${array_ref[i]}"
    if [[ "$current" != "$value" ]]; then
      tempAry+=("$current")
    fi
  done
  array_ref=("${tempAry[@]}")
}


# remove last value from array and return it
# input: <name-of-array-variable>
# stdout: <removed-value>
utb_util_array_pop() {
  declare -n array_ref="$1"
  local value="${array_ref[-1]}"
  unset array_ref[-1]
  printf "$value"
}
