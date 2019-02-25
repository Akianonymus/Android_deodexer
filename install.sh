#!/usr/bin/env bash
# Install or Update Android_deodexer

usage() {
    printf "
The script can be used to install ( or update ) Android_deodexer script in your system.\n
Usage:\n %s [options.. ]\n

All flags are optional.

Options:\n
  -i | --interactive - Install script interactively, will ask for all the varibles one by one.\nNote: This will disregard all arguments given with below flags.\n
  -p | --path <dir_name> - Custom path where you want to install script.\nDefault Path: %s/.Android_deodexer \n
  -c | --cmd <command_name> - Custom command name, after installation script will be available as the input argument.\nDefault Name: deodex \n
  -s | --shell-rc <shell_file> - Specify custom rc file, where PATH is appended, by default script detects .zshrc and .bashrc.\n
  -D | --debug - Display script command trace.\n
  -h | --help - Display usage instructions.\n\n" "${0##*/}" "${HOME}"
    exit 0
}

shortHelp() {
    printf "No valid arguments provided, use -h/--help flag to see usage.\n\n"
    exit 0
}

# Exit if bash present on system is older than 4.x
checkBashVersion() {
    { ! [[ ${BASH_VERSINFO:-0} -ge 4 ]] && printf "Bash version lower than 4.x not supported.\n" && exit 1; } || :
}

# Check if we are running in a terminal.
isTerminal() {
    [[ -t 1 || -z ${TERM} ]] && return 0 || return 1
}

# Update Config. Incase of old value, update, for new value add.
# Usage: updateConfig valuename value configpath
updateConfig() {
    [[ $# -lt 3 ]] && printf "%s: Missing arguments\n" "${FUNCNAME[0]}" && return 1
    declare VALUE_NAME="${1}" VALUE="${2}" CONFIG_PATH="${3}" FINAL=()
    declare -A Aseen
    printf "" >> "${CONFIG_PATH}" # If config file doesn't exist.
    mapfile -t VALUES < "${CONFIG_PATH}" && VALUES+=("${VALUE_NAME}=${VALUE}")
    for i in "${VALUES[@]}"; do
        [[ ${i} =~ ${VALUE_NAME}\= ]] && FINAL+=("${VALUE_NAME}=\"${VALUE}\"") || FINAL+=("${i}")
    done
    for i in "${FINAL[@]}"; do
        [[ ${Aseen[${i}]} ]] && continue
        printf "%s\n" "${i}" && Aseen[${i}]=x
    done >| "${CONFIG_PATH}"
}

# Detect profile file
# Support bash and zsh
detectProfile() {
    declare DETECTED_PROFILE

    if [[ -n "${BASH_VERSION}" ]]; then
        DETECTED_PROFILE="${HOME}/.bashrc"
    elif [[ -n "${ZSH_VERSION}" ]]; then
        DETECTED_PROFILE="${HOME}/.zshrc"
    elif [[ -f "${HOME}/.profile" ]]; then
        DETECTED_PROFILE="${HOME}/.profile"
    fi
    if [[ -n ${DETECTED_PROFILE} ]]; then
        printf "%s\n" "${DETECTED_PROFILE}"
    fi
}

# scrape latest commit from a repo on github
getLatestSHA() {
    declare LATEST_SHA
    case "${1:-${TYPE}}" in
        branch)
            LATEST_SHA="$(hash="$(curl --compressed -s https://github.com/"${3:-${REPO}}"/commits/"${2:-${TYPE_VALUE}}".atom -r 0-1000 | grep "Commit\\/")" && read -r firstline <<< "$hash" && regex="(/.*<)" && [[ $firstline =~ $regex ]] && echo "${BASH_REMATCH[1]:1:-1}")"
            ;;
        release)
            LATEST_SHA="$(hash="$(curl -L --compressed -s https://github.com/"${3:-${REPO}}"/releases/"${2:-${TYPE_VALUE}}" | grep "=\"/""${3:-${REPO}}""/commit")" && read -r firstline <<< "$hash" && : "${hash/*commit\//}" && printf "%s\n" "${_/\"*/}")"
            ;;
    esac

    echo "${LATEST_SHA}"
}

# Move cursor to nth no. of line and clear it to the begining.
clearLine() {
    if isTerminal; then
        printf "\033[%sA\033[2K" "${1}"
    fi
}

# Initialize default variables.
variables() {
    REPO="Akianonymus/Android_deodexer"
    COMMAND_NAME="deodex"
    INFO_PATH="${HOME}/.Android_deodexer"
    INSTALL_PATH="${HOME}/.Android_deodexer/bin"
    PREBUILTS_PATH="${HOME}/.Android_deodexer/prebuilts"
    TYPE="branch"
    TYPE_VALUE="master"
    SHELL_RC="$(detectProfile)"
    # shellcheck source=/dev/null
    if [[ -f ${INFO_PATH}/Android_deodexer.info ]]; then
        source "${INFO_PATH}"/Android_deodexer.info
    fi
}

# Start a interactive session, asks for all the varibles, exit if running in a non-tty
startInteractive() {
    __VALUES_ARRAY=(REPO COMMAND_NAME INSTALL_PATH PREBUILTS_PATH TYPE TYPE_VALUE SHELL_RC)
    printf "%s\n" "Starting Interactive mode.."
    printf "%s\n" "Press return for default values.."
    for i in "${__VALUES_ARRAY[@]}"; do
        j="${!i}" && k="${i}"
        read -r -p "${i} [ Default: ${j} ]: " "${i?}"
        if [[ -z ${!i} ]]; then
            read -r "${k?}" <<< "${j}"
        fi
    done
    for _ in {1..7}; do clearLine 1; done
    for i in "${__VALUES_ARRAY[@]}"; do
        if [[ -n ${i} ]]; then
            printf "%s\n" "${i}: ${!i}"
        fi
    done
}

# Install the script
install() {
    mkdir -p "${INSTALL_PATH}" "${PREBUILTS_PATH}"
    printf 'Installing Android_deodexer..\n'
    printf "Fetching latest sha..\n"
    LATEST_CURRENT_SHA="$(getLatestSHA "${TYPE}" "${TYPE_VALUE}" "${REPO}")"
    clearLine 1
    printf "Latest sha fetched\n" && printf "Downloading script..\n"
    if curl -Ls --compressed "https://raw.githubusercontent.com/${REPO}/${LATEST_CURRENT_SHA}/deodex" -o "${INSTALL_PATH}/${COMMAND_NAME}"; then
        chmod +x "${INSTALL_PATH}/${COMMAND_NAME}"
        __VALUES_ARRAY=(REPO COMMAND_NAME INSTALL_PATH PREBUILTS_PATH TYPE TYPE_VALUE SHELL_RC)
        for i in "${__VALUES_ARRAY[@]}"; do
            updateConfig "${i}" "${!i}" "${INFO_PATH}"/Android_deodexer.info
        done
        updateConfig LATEST_INSTALLED_SHA "${LATEST_CURRENT_SHA}" "${INFO_PATH}"/Android_deodexer.info
        updateConfig PATH "${INSTALL_PATH}:${PATH}" "${INFO_PATH}"/Android_deodexer.vars
        clearLine 1
        printf "\nsource %s/Android_deodexer.vars" "${INFO_PATH}" >> "${SHELL_RC}"
        printf "Installed Successfully, Command name: %s\n" "${COMMAND_NAME}"
        printf "To use the command, do\n"
        printf "source %s or restart your terminal.\n" "${SHELL_RC}"
        printf "To update the script and prebuilt binaries in future, just run upload -u/--update.\n"
    else
        clearLine 1
        printf "Cannot download the script.\n"
        exit 1
    fi
}

# Update the script
update() {
    printf "Fetching latest version info..\n"
    LATEST_CURRENT_SHA="$(getLatestSHA "${TYPE}" "${TYPE_VALUE}" "${REPO}")"
    if [[ -z "${LATEST_CURRENT_SHA}" ]]; then
        printf "Cannot fetch remote latest version.\n"
        exit 1
    fi
    clearLine 1
    if [[ ${LATEST_CURRENT_SHA} = "${LATEST_INSTALLED_SHA}" ]]; then
        printf "Latest Android_deodexer already installed.\n"
    else
        printf "Updating...\n"
        curl --compressed -Ls "https://raw.githubusercontent.com/${REPO}/${LATEST_CURRENT_SHA}/deodex" -o "${INSTALL_PATH}/${COMMAND_NAME}"
        updateConfig LATEST_INSTALLED_SHA "${LATEST_CURRENT_SHA}" "${INFO_PATH}"/Android_deodexer.info
        clearLine 1
        __VALUES_ARRAY=(REPO COMMAND_NAME INSTALL_PATH TYPE TYPE_VALUE SHELL_RC)
        for i in "${__VALUES_ARRAY[@]}"; do
            updateConfig "${i}" "${!i}" "${INFO_PATH}"/Android_deodexer.info
        done
        printf 'Successfully Updated.\n'
    fi
}

downloadPrebuilts() {
    HOST="$(uname)"
    declare STRING REPO=LineageOS/android_prebuilts_tools-lineage BRANCH=lineage-17.1 LATEST_PREBUILT_TAG
    getArch() {
        case "$(uname -m)" in
            'x86_64') STRING=x86 ;;
            *) echo "Not supported architecture" && exit 1 ;;
        esac
    }
    case "${HOST,,}" in
        linux) getArch ;;
        darwin) getArch ;;
    esac

    __BAKSMALIJAR="${PREBUILTS_PATH}"/common/smali/baksmali.jar
    __SMALIJAR="${PREBUILTS_PATH}"/common/smali/smali.jar
    __VDEXEXTRACTOR="${PREBUILTS_PATH}/${HOST,,}-${STRING}"/bin/vdexExtractor
    __CDEXCONVERTER="${PREBUILTS_PATH}/${HOST,,}-${STRING}"/bin/compact_dex_converter

    LATEST_PREBUILT_TAG="$(: "$(getLatestSHA branch "${BRANCH}" "${REPO}")" && printf "%s\n" "${_:0:5}")"

    declare -a URLS=(
        "https://github.com/Akianonymus/Android_deodexer/releases/download/${LATEST_PREBUILT_TAG}/${HOST,,}-${STRING}.tar.gz"
        "https://github.com/Akianonymus/Android_deodexer/releases/download/${LATEST_PREBUILT_TAG}/common.tar.gz"
    )

    if [[ ${LATEST_PREBUILT_TAG} = "${INSTALLED_PREBUILT_TAG}" ]]; then
        printf "Latest prebuilts already on system.\n"
    else
        printf "Downloading prebuilts..\n"
        for URL in "${URLS[@]}"; do
            if curl -C - -# -L "${URL}" -o "${PREBUILTS_PATH}"/__prebuilts.tar.gz; then
                cd "${PREBUILTS_PATH}" || exit
                if tar -xf __prebuilts.tar.gz && rm -f __prebuilts.tar.gz; then
                    cd - 1> /dev/null || exit
                else
                    printf "Error: Cannot extract\n" && return 1
                fi
            else
                printf 'Failed to download prebuilts\n' && exit 1
            fi
        done
        chmod +x -R "${PREBUILTS_PATH}"/*
        export __BAKSMALIJAR __SMALIJAR __VDEXEXTRACTOR __CDEXCONVERTER
        __VALUES_ARRAY=(__BAKSMALIJAR __SMALIJAR __VDEXEXTRACTOR __CDEXCONVERTER)
        for i in "${__VALUES_ARRAY[@]}"; do
            updateConfig "${i}" "${!i}" "${INFO_PATH}"/Android_deodexer.vars
        done
        updateConfig INSTALLED_PREBUILT_TAG "${LATEST_PREBUILT_TAG}" "${INFO_PATH}"/Android_deodexer.info
        printf "All prebuilts downloaded\n"
    fi
}

# Setup the varibles and process getopts flags.
setupArguments() {
    [[ $# = 0 ]] && printf "%s: Missing arguments\n" "${FUNCNAME[0]}" && return 1
    SHORTOPTS=":Dhip:r:c:RB:s:-:"
    while getopts "${SHORTOPTS}" OPTION; do
        case "${OPTION}" in
            # Parse longoptions # https://stackoverflow.com/questions/402377/using-getopts-to-process-long-and-short-command-line-options/28466267#28466267
            -)
                checkLongoptions() { { [[ -n ${!OPTIND} ]] && printf '%s: --%s: option requires an argument\nTry '"%s -h/--help"' for more information.\n' "${0##*/}" "${OPTARG}" "${0##*/}" && exit 1; } || :; }
                case "${OPTARG}" in
                    help)
                        usage
                        ;;
                    interactive)
                        if isTerminal; then
                            INTERACTIVE="true"
                            return 0
                        else
                            printf "Cannot start interactive mode in an non tty environment\n"
                            exit 1
                        fi
                        ;;
                    path)
                        checkLongoptions
                        INSTALL_PATH="${!OPTIND}" && OPTIND=$((OPTIND + 1))
                        ;;
                    cmd)
                        checkLongoptions
                        COMMAND_NAME="${!OPTIND}" && OPTIND=$((OPTIND + 1))
                        ;;
                    shell-rc)
                        checkLongoptions
                        SHELL_RC="${!OPTIND}" && OPTIND=$((OPTIND + 1))
                        ;;
                    debug)
                        DEBUG=true
                        ;;
                    '')
                        shorthelp
                        ;;
                    *)
                        printf '%s: --%s: Unknown option\nTry '"%s -h/--help"' for more information.\n' "${0##*/}" "${OPTARG}" "${0##*/}" && exit 1
                        ;;
                esac
                ;;
            h)
                usage
                ;;
            i)
                if isTerminal; then
                    INTERACTIVE="true"
                    return 0
                else
                    printf "Cannot start interactive mode in an non tty environment.\n"
                    exit 1
                fi
                ;;
            p)
                INSTALL_PATH="${OPTARG}"
                ;;
            c)
                COMMAND_NAME="${OPTARG}"
                ;;
            s)
                SHELL_RC="${OPTARG}"
                ;;
            D)
                DEBUG=true
                ;;
            :)
                printf '%s: -%s: option requires an argument\nTry '"%s -h/--help"' for more information.\n' "${0##*/}" "${OPTARG}" "${0##*/}" && exit 1
                ;;
            ?)
                printf '%s: -%s: Unknown option\nTry '"%s -h/--help"' for more information.\n' "${0##*/}" "${OPTARG}" "${0##*/}" && exit 1
                ;;
        esac
    done
    shift $((OPTIND - 1))

    if [[ -z ${SHELL_RC} ]]; then
        printf "No default shell file found, use -s/--shell-rc to use custom rc file\n"
        exit 1
    else
        if ! [[ -f ${SHELL_RC} ]]; then
            printf "Given shell file ( %s ) does not exist.\n" "${SHELL_RC}"
            exit 1
        fi
    fi
}

# debug mode.
checkDebug() {
    if [[ -n ${DEBUG} ]]; then
        set -x
    else
        set +x
    fi
}

# If internet connection is not available.
# Probably the fastest way, takes about 1 - 2 KB of data, don't check for more than 10 secs.
# curl -m option is unreliable in some cases.
# https://unix.stackexchange.com/a/18711 to timeout without any external program.
checkInternet() {
    if isTerminal; then
        CHECK_INTERNET="$(sh -ic 'exec 3>&1 2>/dev/null; { curl --compressed -Is google.com 1>&3; kill 0; } | { sleep 10; kill 0; }' || :)"
    else
        CHECK_INTERNET="$(curl --compressed -Is google.com -m 10)"
    fi
    if [[ -z ${CHECK_INTERNET} ]]; then
        printf "\n" && printf "Error: Internet connection not available.\n\n"
        exit 1
    fi
}

main() {
    variables
    if [[ $* ]]; then
        setupArguments "${@}"
    fi

    checkDebug && checkBashVersion && checkInternet

    if [[ -n ${INTERACTIVE} ]]; then
        startInteractive
    fi

    if type -a "${COMMAND_NAME}" > /dev/null 2>&1; then
        update
    else
        install
    fi
    downloadPrebuilts
}

main "${@}"
