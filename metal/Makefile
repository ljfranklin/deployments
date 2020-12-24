ifneq ($(SKIP_DOCKER),true)
	DOCKER_IMG := golang:1.11
	DOCKER_CMD := docker pull ${DOCKER_IMG} && docker run -it ${DOCKER_IMG}
endif

.PHONY: default

default: uefi_raspberrypi.img

uefi_raspberrypi.img:
	./scripts/uefi.sh --arch arm64 --platform raspberrypi --output-file uefi_raspberrypi.img
