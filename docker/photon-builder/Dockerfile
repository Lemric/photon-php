# Pre-built RPM toolchain for Photon OS 5.x CI jobs.
# Rebuild when scripts/install-build-deps.sh changes.
FROM photon:5.0

WORKDIR /build

COPY scripts/install-build-deps.sh /tmp/install-build-deps.sh
RUN bash /tmp/install-build-deps.sh && rm -f /tmp/install-build-deps.sh
