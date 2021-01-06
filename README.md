# Unix Toolbox
> A brave attempt to create a modular system for managing dotfiles, shell scripts, settings and other customizations.

## Install
Clone this repository: `git clone https://github.com/unix-toolbox/unix-toolbox.git $HOME/path/to/install/location`

Add the following to e.g. `.bashrc` or `.zshrc`:
```bash
# init unix-toolbox
TOOLBOX_HOME="$HOME/path/to/install/location"
source "$TOOLBOX_HOME/unix-toolbox.sh"
```

Restart your terminal session: e.g. `exec $SHELL`

## Usage
### Modules
Unix Toolbox modules are essentially collections of files that provide a well-defined
and distinct functionality.
It is adviced to stick to the concept of "Do One Thing And Do It Well."
This means modules are easy to share and composable.

Modules are located in `$TOOLBOX_MODULES` and have the following structure:
```bash
$TOOLBOX_MODULES
├── module-1
│   ├── deps.sh # set up all prerequisites for module-1 (sourced) (optional file)
│   ├── load.sh # load all parts of module-1 into the current shell session (sourced) (optional file)
│   └── any other files that may be needed
└── module-2
    └── ...
```
Since `deps.sh` and `load.sh` are ordinary shell scripts and Unix Toolbox sources
both of them on module load, what they should contain is purely conventional.
However, it is important to only set up prerequisites in `deps.sh` since this
provides a clear overview to module users of the other scripts that are needed to run
the module.

If `deps.sh` only contains calls to `utb load <module-name>`, circular dependencies
can be detected before the main code (`load.sh`) is executed. Hence, in case of a
circular dependency, the main code is not executed and the shell environment is not
stained.

Conversely, `load.sh` should contain all lines of code (or delegate it to other files)
that are needed to initialize the module in a user's terminal session.


### Loading a Module
Add the following to e.g. `.bashrc`, `.zshrc` or a module's `deps.sh` file:
```bash
utb load <module-name>
# or more verbose:
utb load-module <module-name>
```

Exit code `10` means that the module could not be loaded due to a circular dependency.

### Commands
`load` in `utb load <module-name>` is already an example of a command.

Modules can add their own commands to the `utb` namespace via the following
steps:

1. Define a function in `load.sh` that uses the following naming pattern: `__utb_command_my_awesome_command`.
   I.e. the function starts with `__utb_command_` and all dashes (`-`) are translated to underscores (`_`).
1. Register the command: `utb load-command my-awesome-command`
1. Invoke your custom command like this: `utb my-awesome-command`
1. Optional: create an alias: `utb alias-command mac my-awesome-command`
1. Optional: invoke your custom command using the alias: `utb mac`

Exit code `10` means that the command was already registered.
Exit code `11` means that the associated function could not be found, hence the
command was not registered.

### Exit Codes
Codes `0` up to (and including) `9` are reserved for Unix Toolbox.

Currently defined:
- `0`: success (bash standard)
- `1`: command not found

Commands are free to assign their own meaning to exit codes starting from number `10`.
Unix Toolbox will properly pass down any exit codes to the calling shell.

> See also: https://tldp.org/LDP/abs/html/exitcodes.html
