ifneq ($(SKIP_DOCKER),true)
	DOCKER_IMG := golang:1.11
	DOCKER_CMD := docker pull ${DOCKER_IMG} && docker run -it ${DOCKER_IMG}
endif

.PHONY: default upload_deb_kernel_5.10_amd64 upload_deb_kernel_5.10_odroid upload_deb_kernel_5.10_arm64

default: uefi_amd64.img uefi_raspberrypi.img uefi_odroid.img

uefi_amd64.img:
	./scripts/uefi.sh --arch amd64 --output-file uefi_amd64.img

uefi_raspberrypi.img:
	./scripts/uefi.sh --arch arm64 --platform raspberrypi --output-file uefi_raspberrypi.img

uefi_odroid.img:
	./scripts/uefi.sh --arch arm --platform odroid --output-file uefi_odroid.img

upload_deb_kernel_5.10_amd64:
	./scripts/kernel_deb.sh --arch x86 --config x86_64_defconfig --dist focal --fullname 'Lyle Franklin' \
		--email 'lylejfranklin@gmail.com' --host ljfranklin/ubuntu/netboot \
		--tag v5.10.9 --suffix '-amd64-1' \
		--secret-file "$(DEB_KEY_FILE)" --key-id "$(DEB_KEY_ID)"

upload_deb_kernel_5.10_odroid:
	./scripts/kernel_deb.sh --arch arm --config odroidxu4_defconfig --dist focal --fullname 'Lyle Franklin' \
		--email 'lylejfranklin@gmail.com' --host ljfranklin/ubuntu/netboot \
		--tag odroid-v5.10.9 --git-url https://github.com/ljfranklin/linux.git --suffix '-odroid-2' \
		--secret-file "$(DEB_KEY_FILE)" --key-id "$(DEB_KEY_ID)"

upload_deb_kernel_5.10_arm64:
	./scripts/kernel_deb.sh --arch arm64 --config defconfig --dist focal --fullname 'Lyle Franklin' \
		--email 'lylejfranklin@gmail.com' --host ljfranklin/ubuntu/netboot --tag v5.10.3 --suffix '-arm64-1' \
		--secret-file "$(DEB_KEY_FILE)" --key-id "$(DEB_KEY_ID)"
