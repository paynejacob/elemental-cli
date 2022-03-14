ARG GOLANG_IMAGE_VERSION=1.17-alpine
ARG COSIGN_VERSION=1.4.1-5
ARG LEAP_VERSION=15.4

FROM quay.io/costoolkit/releases-green:cosign-toolchain-$COSIGN_VERSION AS cosign-bin


FROM golang:$GOLANG_IMAGE_VERSION as elemental-bin
ENV CGO_ENABLED=0
WORKDIR /src/
# Add specific dirs to the image so cache is not invalidated when modifying non go files
ADD go.mod .
ADD go.sum .
RUN go mod download
ADD cmd cmd
ADD internal internal
ADD tests tests
ADD pkg pkg
ADD main.go .
RUN go build -o /usr/bin/elemental

FROM opensuse/leap:$LEAP_VERSION AS elemental
RUN zypper ref
RUN zypper in -y xfsprogs parted util-linux-systemd e2fsprogs util-linux udev rsync grub2
COPY --from=elemental-bin /usr/bin/elemental /usr/bin/elemental
COPY --from=cosign-bin /usr/bin/cosign /usr/bin/cosign
# Fix for blkid only using udev on opensuse
RUN echo "EVALUATE=scan" >> /etc/blkid.conf
ENTRYPOINT ["/usr/bin/elemental"]