# Android Deodexer

This tool can be used to deodex odexed android firmwares.

## Dependencies

Currently, script only works on x86_64 ( intel 64 bit ) systems.

Besides the above, script explicitly requires the following packages:

- Bash ( 4.x )
- java
- find
- zip

## Installation

### Changeable default values set by installation script

Command name: `deodex`

Installation Path: `${HOME}/.Android_deodexer/bin`

Shell file: `.bashrc` or `.zshrc` or `.profile`

For custom command name, shell file, etc, see advanced installation method.

### Basic Installation

To install google-drive-upload in your system, you can run the below command:

`curl --compressed -# -o- https://raw.githubusercontent.com/Akianonymus/Android_deodexer/master/install.sh | bash`

and done.

### Advanced Installation

This section provides on how to utilise the install.sh script fully for custom usescases.

First, we need to download the script, run the following command:

`curl --compressed -# https://raw.githubusercontent.com/Akianonymus/Android_deodexer/master/install.sh -o install.sh`

These are the flags that are available in the install.sh script:

    -i | --interactive - Install script interactively, will ask for all the varibles one by one.

        Note: This will disregard all arguments given with below flags.

    -p | --path <dir_name> - Custom path where you want to install script.

    -c | --cmd <command_name> - Custom command name, after installation script will be available as the input argument.

    -s | --shell-rc <shell_file> - Specify custom rc file, where PATH is appended, by default script detects .zshrc, .bashrc and .profile.

    -D | --debug - Display script command trace.

    -h | --help - Display usage instructions.

Now, run the script and use flags according to your usecase.

E.g: `bash install.sh -p somepath -s shell_file -c command_name`

## Updation

If you have followed the above method to install the script, then you can automatically update the script by running the installation script again.

This will also update the prebuilts if applicable.

## Usage

You can use the script to deodex single files or multiple files.

If you are running the script from a firmware dump, then make sure to change directory to system.

You must have the framework folder inside it, if not, then make one like this `mkdir framework/arch` where arch is cpu architecture ( arm or arm64 ).

For individual files: `deodex file1 file1`

For multiple files' `deodex --all/-a`

### Note: If you use individual files, then a backup of original apk is created. In case of multiple deodexing, vdex/odex files are deleted after deodex.

## Sane pull requests / suggestions / issues reports are always welcome

**Note:** Before submitting a pull request, make sure to format the script ( 4 space intendation - switch cases included ) and it should pass all shellcheck warnings.

If you would like to query something, contact me at [telegram](https://t.me/Akianonymus).
