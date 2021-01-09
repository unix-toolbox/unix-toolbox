#!/usr/bin/env bash


# print <string> <repeat-count> times, with no space between
# input: <string> <repeat-count>
# stdout: <result>
utb_util_string_repeat() {
  local string=$1
  local repeat=${2:-0}
  local result=''
  while [[ $repeat > 0 ]]; do
    result+=$string
    ((repeat--))
  done
  printf "$result"
}


# log strings when in verbose mode
# input: <command> [<string>...]
utb_util_verbose() {
  local command=$1; shift;
  if [[ $TOOLBOX_VERBOSE = 1 ]] || utb_util_array_contains 'TOOLBOX_VERBOSE' "$command"; then
    utb_util_string_repeat '\t' ${#__TOOLBOX_COMMAND_STACK[@]} # output tabs without spawning subshell
    local style='32' && [[ $command == 'execute-command' ]] && style='31'
    echo -e "\033["$style"m$command:\033[0m $@"
  fi
}
