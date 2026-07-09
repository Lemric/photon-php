# VMware Photon OS 5.x — PHP 8.5 RPM build environment
FROM photon:5.0 AS builder

LABEL maintainer="Photon PHP Build <build@photon-php.local>"
LABEL description="RPM build environment for PHP 8.5 on Photon OS"

ENV PHP_VERSION=8.5.8 \
    LANG=C.UTF-8 \
    RPMBUILD_DIR=/rpmbuild \
    OUTPUT_DIR=/output

COPY packaging/ /build/packaging/
COPY extensions/ /build/extensions/
COPY scripts/ /build/scripts/

RUN chmod +x /build/scripts/*.sh && \
    /build/scripts/install-build-deps.sh

WORKDIR /build

ENTRYPOINT ["/build/scripts/build-rpm.sh"]
CMD ["all"]
