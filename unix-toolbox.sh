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
export __TOOLBOX_LOADED_COMMANDS=(load load-module load-command)
export __TOOLBOX_LOADING_STACK=()
export __TOOLBOX_EXIT_CODE=0 # propagate error codes down the stack


# public api
# usage: utb <command> [<arguments> ...]
# e.g. utb load <module-name>
# e.g. utb load-command <command-name>
# return 0 (success), 1 (command not found), > 9 (command-specific exit code)
utb() {
  local command="$1"; shift
  local function="__utb_command_${command//-/_}"
  if $(type "$function" > /dev/null 2>&1) && __utb_array_contains "$command" "${__TOOLBOX_LOADED_COMMANDS[@]}"
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


# return 0 (found) or 1 (not found)
__utb_array_contains() {
  # first argument: needle
  # other arguments: haystack
  local needle="$1"; shift
  
  # loop over remaining arguments
  local item
  for item; do
    [[ "$item" == "$needle" ]] && return 0
  done
  return 1
}


__utb_continue() {
  return $__TOOLBOX_EXIT_CODE
}


# return 0 (loaded) or 1 (not loaded)
__utb_module_is_loaded() {
  __utb_array_contains "$1" "${__TOOLBOX_LOADED_MODULES[@]}"
}


# return 0 (circular dependency) or 1 (no circular dependency)
__utb_module_is_circular() {
  __utb_array_contains "$1" "${__TOOLBOX_LOADING_STACK[@]}"
}

__utb_add_module_to_stack() {
  local module_name="$1"
  __TOOLBOX_LOADING_STACK+=("$module_name")
}

__utb_remove_module_from_stack() {
  local module_name="$1"
  local i tempAry=()
  for i in "${!__TOOLBOX_LOADING_STACK[@]}"; do
    local val="${__TOOLBOX_LOADING_STACK[i]}"
    if [[ "$val" != "$module_name" ]]; then
      tempAry+=("$val")
    fi
  done
  export __TOOLBOX_LOADING_STACK=("${tempAry[@]}")
}


# load a module
# usage: utb load <module-name>
#        utb load-module <module-name>
# => load $TOOLBOX_MODULES/module-name and its dependencies
# return 0 (success: module loaded) or 10 (failed due to circular dependency)
__utb_command_load() {
  __utb_command_load_module $@
}
__utb_command_load_module() {
  # inputs
  local module_name="$1"

  # skip if module was already loaded
  if __utb_module_is_loaded "$module_name"; then
    return $__TOOLBOX_EXIT_CODE
  fi

  # error if circular dependency
  if __utb_module_is_circular "$module_name"; then
    echo "error: circular dependency: ${__TOOLBOX_LOADING_STACK[@]} $module_name" >&2
    __TOOLBOX_EXIT_CODE=10 # failed due to circular dependency
    return $__TOOLBOX_EXIT_CODE
  fi

  # set module loading
  __utb_add_module_to_stack "$module_name"

  # setup module dependencies
  local module_dependency_path="$TOOLBOX_MODULES/$module_name/deps.sh"
  __utb_continue && [[ -f $module_dependency_path ]] && source "$module_dependency_path"

  # load module
  local module_load_path="$TOOLBOX_MODULES/$module_name/load.sh"
  __utb_continue && [[ -f $module_load_path ]] && source "$module_load_path"

  # set module loaded
  __utb_remove_module_from_stack "$module_name"
  __TOOLBOX_LOADED_MODULES+=("$module_name")

  return $__TOOLBOX_EXIT_CODE
}

# add a new command to the public api
# usage: utb load-command <command-name>
# => utb <command-name> will call __utb_command_command_name and pass arguments
# return 0 (success), 10 (command already registered), 11 (function not found)
__utb_command_load_command() {
  local command="$1"
  if __utb_array_contains "$command" "${__TOOLBOX_LOADED_COMMANDS[@]}"; then
    echo "error: command '$command' was already registered."
    return 10
  fi

  local function="__utb_command_${command//-/_}"
  if ! $(type "$function" > /dev/null 2>&1); then
    echo "error: could not find function for command '$command'."
    return 11
  fi

  __TOOLBOX_LOADED_COMMANDS+=("$command")
}
