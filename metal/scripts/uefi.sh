#!/bin/bash

set -eu -o pipefail

project_dir="$( cd "$( dirname "$0" )" && cd .. && pwd )"
tmpdir="$(mktemp -d /tmp/uefi.XXXXX)"
build_dir="${tmpdir}/build"
mkdir "${build_dir}"

cleanup() {
  if [ -n "${loop_device:-}" ]; then
    umount "${loop_device}"
    udisksctl loop-delete -b "${loop_device}" --no-user-interaction
  fi
  rm -rf "${tmpdir}"
}
trap 'cleanup' EXIT

print_help() {
  cat <<EOF
${BASH_SOURCE[0]} [OPTION]...

Builds UEFI boot images

 Options:
  -a, --arch <arch>          The target architecture: armhf, arm64, amd64
  -p, --platform <platform>  The target platform: raspberrypi, odroid_xu4
  -o, --output-file <file>   The output filepath
  -h, --help                 Display this help and exit
EOF
}

arch=""
platform=""
output_file=""
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
    -o|--output-file)
      shift
      if [ "$#" -gt 0 ]; then
        output_file="$1"
      else
        echo "--output-file requires an argument"
        exit 1
      fi
      shift
      ;;
    -p|--platform)
      shift
      if [ "$#" -gt 0 ]; then
        platform="$1"
      else
        echo "--platform requires an argument"
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
if [ "${arch}" != "amd64" ] && [ -z "${platform}" ]; then
  echo "Flag --platform <platform> is required for non-amd64 architecture"
  exit 1
fi
if [ -z "${output_file}" ]; then
  echo "Flag --output-file <file> is required"
  exit 1
fi

dd if=/dev/zero "of=${output_file}" bs=1024 count=10000
mkfs.vfat "${output_file}"
loop_device="$(udisksctl loop-setup -f "${output_file}" | grep -o '/dev/loop[0-9]\+')"
set +e
# swallow error code since OS may auto-mount new devices
udisksctl mount -b "${loop_device}"
set -e
img_dir="$(mount | grep "^${loop_device} " | awk '{ print $3}')"

build_edk2_raspberrypi() {
  pushd "${build_dir}" > /dev/null
    wget -O firmware.tar.gz https://github.com/raspberrypi/firmware/archive/1.20201022.tar.gz
    mkdir ./firmware
    tar xf firmware.tar.gz --strip-components=1 -C firmware
    mkdir "${img_dir}/overlays"
    boot_files="bootcode.bin start.elf start4.elf fixup.dat fixup4.dat bcm2711-rpi-4-b.dtb bcm2710-rpi-3-b-plus.dtb bcm2710-rpi-3-b.dtb overlays/disable-bt.dtbo overlays/disable-wifi.dtbo"
    for boot_file in ${boot_files}; do
      cp "./firmware/boot/${boot_file}" "${img_dir}/${boot_file}"
    done
    cp "${project_dir}"/templates/raspberrypi/config.txt "${img_dir}"

    git clone --depth 1 https://github.com/tianocore/edk2 -b edk2-stable202011
    pushd edk2 > /dev/null
      git submodule update --init
    popd > /dev/null
    wget -O edk2-non-osi.tar.gz https://github.com/tianocore/edk2-non-osi/archive/3d1bb660664bcacb07bbfaa690e7b2cc35c412f3.tar.gz
    mkdir ./edk2-non-osi
    tar xf edk2-non-osi.tar.gz --strip-components=1 -C edk2-non-osi
    wget -O edk2-platforms.tar.gz https://github.com/tianocore/edk2-platforms/archive/3f71a8fb114ae9ce87281eb30ab0e678f6806b05.tar.gz
    mkdir ./edk2-platforms
    tar xf edk2-platforms.tar.gz --strip-components=1 -C edk2-platforms
    export WORKSPACE=$PWD
    export PACKAGES_PATH=$PWD/edk2:$PWD/edk2-platforms:$PWD/edk2-non-osi
    export GCC5_AARCH64_PREFIX=aarch64-linux-gnu-
    export EDK_TOOLS_PATH=$PWD/edk2/BaseTools
    export CONF_PATH=$PWD/edk2/Conf
    export PYTHON_COMMAND=python
    export PYTHON3_ENABLE=TRUE
    export origin_version=''
    pushd "edk2" > /dev/null
      # HACK: Force our GRUB wrapper to always boot first.
      find . -type f -exec sed -i 's/BOOTAA64\.EFI/WRAPPER\.EFI/g' {} +

      make -C BaseTools
      source edksetup.sh BaseTools
      build -n "$((`getconf _NPROCESSORS_ONLN` + 2))" -a AARCH64 -t GCC5 -p Platform/RaspberryPi/RPi3/RPi3.dsc
    popd > /dev/null
    cp Build/RPi3/DEBUG_GCC5/FV/RPI_EFI.fd "${img_dir}"
  popd > /dev/null
}

build_grub_raspberrypi() {
  pushd "${build_dir}" > /dev/null
    wget -O grub.tar.gz https://ftp.gnu.org/gnu/grub/grub-2.04.tar.gz
    mkdir ./grub
    tar xf grub.tar.gz --strip-components=1 -C grub
    pushd grub > /dev/null
      ./autogen.sh
      ./configure --with-platform=efi --target=aarch64-linux-gnu --disable-werror
      make -j "$((`getconf _NPROCESSORS_ONLN` + 2))"
      mkdir -p "${img_dir}/EFI/boot"
      all_modules="$(find grub-core/ -name '*.mod' -exec basename {} .mod ';')"
      # Use a non-standard prefix to ensure the wrapper always loads first.
      ./grub-mkimage --directory grub-core --format arm64-efi \
        --prefix /EFI/boot/wrapper --output "${img_dir}/EFI/boot/wrapper.efi" \
        ${all_modules}
      mkdir -p "${img_dir}/EFI/boot/wrapper"
      cp "${project_dir}"/templates/raspberrypi/grub.cfg "${img_dir}/EFI/boot/wrapper/"
    popd > /dev/null
  popd > /dev/null
}

if [ "${arch}" = "arm64" ] && [ "${platform}" = "raspberrypi" ]; then
  build_edk2_raspberrypi
  build_grub_raspberrypi
else
  echo "Unknown arch + platform combination"
  exit 1
fi
