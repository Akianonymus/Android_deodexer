#!/usr/bin/env bash

REPO=LineageOS/android_prebuilts_tools-lineage
BRANCH=lineage-17.1

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

STRING="${RANDOM}"

curl -L https://github.com/"${REPO}"/archive/"${BRANCH}".zip -o prebuilts.zip -#

dir="${PWD}"

mkdir -p "${STRING}"

cd "${STRING}" || exit 1

unzip ../prebuilts.zip 1> /dev/null 2>&1
rm -f ../prebuilts.zip
cd ./*

tar -czf linux-x86.tar.gz linux-x86
tar -czf darwin-x86.tar.gz darwin-x86
tar -czf common.tar.gz common

TAG="$(: "$(getLatestSHA branch "${BRANCH}" "${REPO}")" && printf "%s\n" "${_:0:5}")"
hub release create -a common.tar.gz -a linux-x86.tar.gz -a darwin-x86.tar.gz -m "Latest binaries." "${TAG}"

cd "${dir}" || exit 1

rm -rf "${STRING}"
