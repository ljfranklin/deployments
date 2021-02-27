#!/bin/bash

set -eu -o pipefail

project_dir="$( cd "$( dirname "$0" )" && cd .. && pwd )"
tmpdir="$(mktemp -d /tmp/uefi.XXXXX)"

cleanup() {
  rm -rf "${tmpdir}"
}
trap 'cleanup' EXIT

default_git_repo='https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git'

print_help() {
  cat <<EOF
${BASH_SOURCE[0]} [OPTION]...

Uploads a kernel deb package

 Options:
  -a, --arch <arch>        The target architecture: arm, arm64, x86
  -c, --config <config>    The target config: bcmrpi3_defconfig, exynos_defconfig
  -d, --dist <dist>        Package distribution, e.g. focal
  -n, --fullname <name>    The maintainer's name
  -e, --email <email>      The maintainer's email
  -s, --secret-file <file> The secret gpg file to import for signing
  -k, --key-id <id>        The gpg key ID to use for signing
  -o, --host <host>        The dput host address for upload, e.g. ppa:ljfranklin/ubuntu/netboot
  -t, --tag <tag>          The target linux git tag, e.g. v5.4.79
  -g, --git-url <url>      The target linux git repo, defaults to ${default_git_repo}
  -x, --suffix <suffix>    (optional) A suffix to append to version
  -h, --help               Display this help and exit
EOF
}

arch=""
config=""
dist=""
fullname=""
email=""
secret_file=""
key_id=""
host=""
tag=""
suffix=""
git_repo="${default_git_repo}"
while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help)
      print_help
      exit 0
      ;;
    -a|--arch)
      shift
      if [ "$#" -gt 0 ]; then
        arch="$1"
      else
        echo "--arch requires an argument"
        exit 1
      fi
      shift
      ;;
    -c|--config)
      shift
      if [ "$#" -gt 0 ]; then
        config="$1"
      else
        echo "--config requires an argument"
        exit 1
      fi
      shift
      ;;
    -d|--dist)
      shift
      if [ "$#" -gt 0 ]; then
        dist="$1"
      else
        echo "--dist requires an argument"
        exit 1
      fi
      shift
      ;;
    -f|--fullname)
      shift
      if [ "$#" -gt 0 ]; then
        fullname="$1"
      else
        echo "--fullname requires an argument"
        exit 1
      fi
      shift
      ;;
    -e|--email)
      shift
      if [ "$#" -gt 0 ]; then
        email="$1"
      else
        echo "--email requires an argument"
        exit 1
      fi
      shift
      ;;
    -s|--secret-file)
      shift
      if [ "$#" -gt 0 ]; then
        secret_file="$1"
      else
        echo "--secret-file requires an argument"
        exit 1
      fi
      shift
      ;;
    -k|--key-id)
      shift
      if [ "$#" -gt 0 ]; then
        key_id="$1"
      else
        echo "--key-id requires an argument"
        exit 1
      fi
      shift
      ;;
    -o|--host)
      shift
      if [ "$#" -gt 0 ]; then
        host="$1"
      else
        echo "--host requires an argument"
        exit 1
      fi
      shift
      ;;
    -t|--tag)
      shift
      if [ "$#" -gt 0 ]; then
        tag="$1"
      else
        echo "--tag requires an argument"
        exit 1
      fi
      shift
      ;;
    -x|--suffix)
      shift
      if [ "$#" -gt 0 ]; then
        suffix="$1"
      else
        echo "--suffix requires an argument"
        exit 1
      fi
      shift
      ;;
    -g|--git-url)
      shift
      if [ "$#" -gt 0 ]; then
        git_repo="$1"
      else
        echo "--git-url requires an argument"
        exit 1
      fi
      shift
      ;;
    *)
      echo "Unrecognized argument '$1'"
      print_help
      exit 1
      ;;
  esac
done

if [ -z "${arch}" ]; then
  echo "Flag --arch <arch> is required"
  exit 1
fi
if [ -z "${config}" ]; then
  echo "Flag --config <config> is required"
  exit 1
fi
if [ -z "${dist}" ]; then
  echo "Flag --dist <dist> is required"
  exit 1
fi
if [ -z "${fullname}" ]; then
  echo "Flag --fullname <name> is required"
  exit 1
fi
if [ -z "${email}" ]; then
  echo "Flag --email <email> is required"
  exit 1
fi
if [ -z "${secret_file}" ]; then
  echo "Flag --secret-file <file> is required"
  exit 1
fi
if [ -z "${key_id}" ]; then
  echo "Flag --key_id <key_id> is required"
  exit 1
fi
if [ -z "${host}" ]; then
  echo "Flag --host <host> is required"
  exit 1
fi
if [ -z "${tag}" ]; then
  echo "Flag --tag <tag> is required"
  exit 1
fi

pushd "${tmpdir}" > /dev/null
  gpg --import "${secret_file}"

  git clone --depth=1 --branch="${tag}" "${git_repo}"
  pushd linux > /dev/null
    rm -rf .git
    ARCH="${arch}" make "${config}"
    ARCH="${arch}" KDEB_CHANGELOG_DIST="${dist}" DEBFULLNAME="${fullname}" DEBEMAIL="${email}" \
      DPKG_FLAGS='-S -d' make -j "$((`getconf _NPROCESSORS_ONLN` + 2))" -e EXTRAVERSION="${suffix}" deb-pkg
   debsign -k "${key_id}" ../linux-*_source.changes
    cat <<EOF > ../dput.cf
[my-ppa]
fqdn = ppa.launchpad.net
method = ftp
incoming = ~${host}
login = anonymous
allow_unsigned_uploads = 0
EOF
    dput -c ../dput.cf my-ppa ../linux-*_source.changes
  popd > /dev/null
popd > /dev/null
