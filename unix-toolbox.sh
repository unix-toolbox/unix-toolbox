#!/usr/bin/env bash


# Source this file to initialize unix-toolbox. Certain commands
# provided by unix-toolbox will modify the current shell environment.
# (e.g. add functions, add/modify env vars...)


# use user-defined $TOOLBOX_HOME or derive from this file's location
export TOOLBOX_HOME=${TOOLBOX_HOME:-$(dirname $(realpath ${BASH_SOURCE[0]}))}

# use user-defined $TOOLBOX_MODULES or derive from $TOOLBOX_HOME
export TOOLBOX_MODULES=${TOOLBOX_MODULES:-"$TOOLBOX_HOME/modules"}


# internal state
export __TOOLBOX_EXIT_CODE=0 # propagate error codes down the stack
export __TOOLBOX_LOADED_MODULES=()
export __TOOLBOX_LOADING_STACK=()


# public api
# usage: utb load <module-name>
utb() {
  local command=$1
  [[ $command == "load" ]] && __utb_load_module $2
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


# return 0 (module loaded) or 1 (failed due to circular dependency)
__utb_load_module() {
  # inputs
  local module_name="$1"

  # skip if module was already loaded
  if __utb_module_is_loaded "$module_name"; then
    return $__TOOLBOX_EXIT_CODE
  fi

  # error if circular dependency
  if __utb_module_is_circular "$module_name"; then
    echo "error: circular dependency: ${__TOOLBOX_LOADING_STACK[@]} $module_name" >&2
    __TOOLBOX_EXIT_CODE=1
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
