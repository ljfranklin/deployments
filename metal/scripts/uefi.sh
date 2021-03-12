#!/bin/bash

set -eu -o pipefail

project_dir="$( cd "$( dirname "$0" )" && cd .. && pwd )"
tmpdir="$(mktemp -d /tmp/uefi.XXXXX)"
build_dir="${tmpdir}/build"
img_dir="${tmpdir}/img"
mkdir "${build_dir}"
mkdir "${img_dir}"

umount_loop_device() {
  if [ -n "${loop_device:-}" ]; then
    sudo umount "${img_dir}"
    sudo losetup -d "${loop_device}"
    unset loop_device
  fi
}

cleanup() {
  umount_loop_device
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

dd if=/dev/zero "of=${output_file}" bs=1024 count=50000
parted "${output_file}" --script -- mklabel msdos
parted "${output_file}" --script -- mkpart primary fat32 4096s 100%
sudo losetup -o "$((4096 * 512))" -f "${output_file}"
loop_device="$(losetup -j "${output_file}" | grep -o '/dev/loop[0-9]\+')"
sudo mkfs.vfat "${loop_device}"
user_id="$(id -u "$(whoami)")"
group_id="$(id -g "$(whoami)")"
sudo mount -o loop,nosuid,uid="${user_id}",gid="${group_id}" \
  "${loop_device}" "${img_dir}"

build_edk2_raspberrypi() {
  pushd "${build_dir}" > /dev/null
    # Use 'stable' branch.
    # wget -O firmware.tar.gz https://github.com/raspberrypi/firmware/archive/fcf8d2f7639ad8d0330db9c8db9b71bd33eaaa28.tar.gz
    wget -O firmware.tar.gz https://github.com/raspberrypi/firmware/archive/1711f63174c5bfe147cc903af14e99a36938c105.tar.gz
    mkdir ./firmware
    tar xf firmware.tar.gz --strip-components=1 -C firmware
    mkdir "${img_dir}/overlays"
    boot_files="bootcode.bin start.elf start4.elf fixup.dat fixup4.dat bcm2711-rpi-4-b.dtb bcm2710-rpi-3-b-plus.dtb bcm2710-rpi-3-b.dtb overlays/disable-bt.dtbo overlays/disable-wifi.dtbo"
    for boot_file in ${boot_files}; do
      cp "./firmware/boot/${boot_file}" "${img_dir}/${boot_file}"
    done
    cp "${project_dir}"/templates/raspberrypi/config.txt "${img_dir}"

    git clone https://github.com/tianocore/edk2
    pushd edk2 > /dev/null
      git reset --hard 59a3ccb09e7a246913d88fbac31412f20f717a3c
      git submodule update --init
    popd > /dev/null
    wget -O edk2-non-osi.tar.gz https://github.com/tianocore/edk2-non-osi/archive/04744d2432baedb59382f090a2d22e23f6c4d215.tar.gz
    mkdir ./edk2-non-osi
    tar xf edk2-non-osi.tar.gz --strip-components=1 -C edk2-non-osi
    # TODO(ljfranklin): Switch back to upstream after patch is merged:
    # https://github.com/pftf/RPi4/issues/122#issuecomment-797465514
    git clone https://github.com/rtreffer/edk2-platforms
    pushd edk2-platforms > /dev/null
      git reset --hard ca053c606c216a0d90239e5fdcbd5118aa0660d6
    popd > /dev/null
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
      build -n "$((`getconf _NPROCESSORS_ONLN` + 2))" -a AARCH64 -t GCC5 -b RELEASE \
        -p Platform/RaspberryPi/RPi3/RPi3.dsc --pcd=PcdPlatformBootTimeOut=3
    popd > /dev/null
    cp Build/RPi3/RELEASE_GCC5/FV/RPI_EFI.fd "${img_dir}"
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

build_ipxe_raspberrypi() {
  pushd "${build_dir}" > /dev/null
    wget -O ipxe.tar.gz https://github.com/ipxe/ipxe/archive/65bd5c05db2a050a4c0f26ccc0b1e9828b00abbf.tar.gz
    mkdir ./ipxe
    tar xf ipxe.tar.gz --strip-components=1 -C ipxe
    pushd ipxe/src > /dev/null
      wget https://raw.githubusercontent.com/danderson/netboot/bdaec9d82638460bf166fb98bdc6d97331d7bd80/pixiecore/boot.ipxe
      CROSS_COMPILE=aarch64-linux-gnu- EMBED=boot.ipxe CONFIG=rpi \
        make -j "$((`getconf _NPROCESSORS_ONLN` + 2))" bin-arm64-efi/rpi.efi
      mkdir -p "${img_dir}/EFI/boot/"
      cp bin-arm64-efi/rpi.efi "${img_dir}/EFI/boot/ipxe.efi"
    popd > /dev/null
  popd > /dev/null
}

build_uboot_odroid() {
  pushd "${build_dir}" > /dev/null
    # Use custom 'deploy-odroid_v2020.01' branch which is based on hardkernel's v2020.01 branch + ProxyDHCP support.
    # I got Linux to boot with mainline u-boot but the kernel couldn't see any USB devices.
    wget -O uboot.tar.gz https://github.com/ljfranklin/u-boot/archive/c3db827e12e1b058c1e84c334dfd182c27f3359e.tar.gz
    mkdir ./uboot
    tar xf uboot.tar.gz --strip-components=1 -C uboot
    pushd uboot > /dev/null
      echo 'CONFIG_SERVERIP_FROM_PROXYDHCP=y' >> configs/odroid-xu3_defconfig
      CROSS_COMPILE=arm-linux-gnueabihf- make odroid-xu3_defconfig
      CROSS_COMPILE=arm-linux-gnueabihf- make all
    popd > /dev/null

    cp uboot/u-boot-dtb.bin .
    odroid_src_url="https://github.com/hardkernel/u-boot/raw/odroidxu3-v2012.07"
    wget "${odroid_src_url}/sd_fuse/hardkernel_1mb_uboot/bl1.bin.hardkernel"
    wget "${odroid_src_url}/sd_fuse/hardkernel_1mb_uboot/bl2.bin.hardkernel.1mb_uboot"
    wget "${odroid_src_url}/sd_fuse/hardkernel_1mb_uboot/tzsw.bin.hardkernel"

    mkdir kernel_deb
    pushd kernel_deb > /dev/null
      wget -O linux.deb https://launchpad.net/~ljfranklin/+archive/ubuntu/netboot/+files/linux-image-5.10.9-odroid-2_5.10.9-odroid-2-1_armhf.deb
      dpkg -x linux.deb .
    popd > /dev/null
    cp $(find kernel_deb -name 'exynos5422-odroidxu4.dtb') "${img_dir}/"
  popd > /dev/null
}

# TODO: Grub 2.04 fails to load under u-boot
build_grub_odroid() {
  pushd "${build_dir}" > /dev/null
    # wget -O grub.tar.gz https://ftp.gnu.org/gnu/grub/grub-2.02.tar.gz
    wget -O grub.tar.gz https://github.com/ljfranklin/grub/archive/81b51afebb087c655e2c4a3ec2e4eacfdbdd96f9.tar.gz
    mkdir ./grub
    tar xf grub.tar.gz --strip-components=1 -C grub
    pushd grub > /dev/null
      ./autogen.sh
      ./configure --with-platform=efi --target=arm-linux-gnueabihf --disable-werror
      make -j "$((`getconf _NPROCESSORS_ONLN` + 2))"
      mkdir -p "${img_dir}/EFI/boot"
      all_modules="$(find grub-core/ -name '*.mod' -exec basename {} .mod ';')"
      # Use a non-standard prefix to ensure the wrapper always loads first.
      ./grub-mkimage --directory grub-core --format arm-efi \
        --prefix /EFI/boot/wrapper --output "${img_dir}/EFI/boot/wrapper.efi" \
        ${all_modules}
      mkdir -p "${img_dir}/EFI/boot/wrapper"
      cp "${project_dir}"/templates/odroid/grub.cfg "${img_dir}/EFI/boot/wrapper/"
      cp "${project_dir}"/templates/odroid/cmdline.cfg "${img_dir}/"
      cp "${project_dir}"/templates/odroid/boot.txt "${img_dir}/"
      mkimage -A arm -T script -C none -d "${img_dir}/boot.txt" "${img_dir}/boot.scr"
    popd > /dev/null
  popd > /dev/null
}

finalize_odroid_img() {
  umount_loop_device
  # Adapted from https://github.com/hardkernel/u-boot/blob/odroidxu3-v2012.07/sd_fuse/hardkernel_1mb_uboot/sd_fusing.1M.sh
  dd if="${build_dir}/bl1.bin.hardkernel" of="${output_file}" seek=1 bs=512 conv=notrunc
  dd if="${build_dir}/bl2.bin.hardkernel.1mb_uboot" of="${output_file}" seek=31 bs=512 conv=notrunc
  dd if="${build_dir}/u-boot-dtb.bin" of="${output_file}" seek=63 bs=512 conv=notrunc
  dd if="${build_dir}/tzsw.bin.hardkernel" of="${output_file}" seek=2111 bs=512 conv=notrunc
}

if [ "${arch}" = "arm64" ] && [ "${platform}" = "raspberrypi" ]; then
  build_edk2_raspberrypi
  build_grub_raspberrypi
  build_ipxe_raspberrypi
elif [ "${arch}" = "arm" ] && [ "${platform}" = "odroid" ]; then
  build_uboot_odroid
  build_grub_odroid
  finalize_odroid_img
else
  echo "Unknown arch + platform combination"
  exit 1
fi
