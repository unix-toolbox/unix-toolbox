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
provides a clear overview to module users of other scripts that are needed to run the
module.

Conversely, `load.sh` should contain all lines of code (or delegate it to other files)
that are needed to initialize the module in a user's terminal session.


### Loading a Module
Add the following to e.g. `.bashrc`, `.zshrc` or a module's `deps.sh` file:
```bash
utb load module-name
```
