#!/usr/bin/env bash

# load a module and its dependencies
# modules are child folders of $TOOLBOX_MODULES
# input: <module-name>
# return: 0 (success: module loaded) or 10 (failed due to circular dependency)
__utb_command_load_module() {
  local module_name="$1"

  # skip if module was already loaded
  # NOTE: this is not considered an error and expected to occur often
  if utb_util_array_contains '__TOOLBOX_LOADED_MODULES' "$module_name"; then
    utb_util_verbose 'load-module' "$module_name (skip)"
    return $__TOOLBOX_EXIT_CODE
  fi
  utb_util_verbose 'load-module' "$module_name (new)"

  # error if circular dependency
  if utb_util_array_contains '__TOOLBOX_LOADING_STACK' "$module_name"; then
    echo "error: circular dependency: ${__TOOLBOX_LOADING_STACK[@]} $module_name" >&2
    __TOOLBOX_EXIT_CODE=10 # failed due to circular dependency
    return $__TOOLBOX_EXIT_CODE
  fi

  # set module loading
  utb_util_array_add '__TOOLBOX_LOADING_STACK' "$module_name"

  # load module dependencies
  local module_dependency_path="$TOOLBOX_MODULES/$module_name/deps.sh"
  if [[ $__TOOLBOX_EXIT_CODE == 0 && -f $module_dependency_path ]]; then
    utb_util_verbose 'load-module' "source $module_name/deps.sh"
    source "$module_dependency_path"
  fi

  # load module
  local module_load_path="$TOOLBOX_MODULES/$module_name/load.sh"
  if [[ $__TOOLBOX_EXIT_CODE == 0 && -f $module_load_path ]]; then
    utb_util_verbose 'load-module' "source $module_name/load.sh"
    source "$module_load_path"
  fi

  # set module loaded
  utb_util_array_remove '__TOOLBOX_LOADING_STACK' "$module_name"
  utb_util_array_add '__TOOLBOX_LOADED_MODULES' "$module_name"

  return $__TOOLBOX_EXIT_CODE
}
