# CI builds this image with privileged "docker run" + "docker commit" (_rpm-ci.yml).
# Local equivalent:
#   docker run --privileged -v "$PWD/scripts/install-build-deps.sh:/tmp/s:ro" \
#     --name photon-builder photon:5.0 bash /tmp/s
#   docker commit photon-builder photon-php-builder:local
FROM photon:5.0

WORKDIR /build
