#!/usr/bin/env bash


# Source this file to initialize unix-toolbox. Certain commands
# provided by unix-toolbox will modify the current shell environment.
# (e.g. add functions, add/modify env vars...)


# use user-defined $TOOLBOX_HOME or derive from this file's location
export TOOLBOX_HOME=${TOOLBOX_HOME:-$(dirname $(realpath ${BASH_SOURCE[0]}))}

# use user-defined $TOOLBOX_MODULES or derive from $TOOLBOX_HOME
export TOOLBOX_MODULES=${TOOLBOX_MODULES:-"$TOOLBOX_HOME/modules"}


# internal state
export __TOOLBOX_LOADED_MODULES=()
export __TOOLBOX_LOADED_COMMANDS=()
export __TOOLBOX_LOADING_STACK=()
export __TOOLBOX_EXIT_CODE=0 # propagate error codes down the stack


# libraries
source "$TOOLBOX_HOME/lib/array-utils.sh"
source "$TOOLBOX_HOME/lib/command-loader.sh"
source "$TOOLBOX_HOME/lib/module-loader.sh"


# public api
# input: <command> [<arguments> ...]
# return: 0 (success), 1 (command not found), > 9 (command-specific exit code)
utb() {
  local command="$1"; shift
  local function=$(__utb_cmd_to_func "$command")
  if $(type "$function" > /dev/null 2>&1) && utb_util_array_contains '__TOOLBOX_LOADED_COMMANDS' "$command"
  then
    # execute function and capture exit code
    __TOOLBOX_EXIT_CODE=0; $function $@; __TOOLBOX_EXIT_CODE=$?
  else
    # command not found
    echo "error: command '$command' not found. Is it registered?"
    __TOOLBOX_EXIT_CODE=1
  fi
  return $__TOOLBOX_EXIT_CODE
}


# provide: utb load-command <command-name>
__utb_command_load_command 'load-command'

# provide: utb alias-command <alias-name> <command-name>
utb load-command 'alias-command'

# provide: utb load-module <module-name>
utb load-command 'load-module'

# provide: utb load <module-name>
utb alias-command 'load' 'load-module'
