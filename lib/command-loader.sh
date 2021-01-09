#!/usr/bin/env bash


# NOTE: prefix __utb_command has special meaning already!
# translate command into function name
# input: <command-name>
# stdout: the function name associated with <command-name>
__utb_cmd_to_func() {
  local command="$1"
  echo "__utb_command_${command//-/_}"
}


# add a new command to the public api
# input: <command-name>
# return: 0 (success), 10 (command already registered), 11 (function not found)
__utb_command_load_command() {
  local command="$1"
  utb_util_verbose 'load-command' "$command"

  # load command only once
  if utb_util_array_contains '__TOOLBOX_LOADED_COMMANDS' "$command"; then
    echo "error: command '$command' was already registered."
    return 10
  fi

  # make sure command function exists
  local function=$(__utb_cmd_to_func "$command")
  if ! $(type "$function" > /dev/null 2>&1); then
    echo "error: could not find function for command '$command'."
    return 11
  fi

  # add command to namespace
  utb_util_array_add '__TOOLBOX_LOADED_COMMANDS' "$command"
}


# add an alias to the public api
# input: <alias-name> <command-name>
__utb_command_alias_command() {
  local alias="$1"
  local command="$2"
  utb_util_verbose 'alias-command' "$alias -> $command"
  local alias_function_name=$(__utb_cmd_to_func "$alias")
  local command_function_name=$(__utb_cmd_to_func "$command")
  eval "$alias_function_name() { utb_util_verbose 'execute-alias' '$alias -> $command'; $command_function_name \$@ ; }"
  __utb_command_load_command "$alias"
}
