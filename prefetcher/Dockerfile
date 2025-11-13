ARG VERSION_PARENT=v0.0.57

FROM gitlab-registry.cern.ch/swan/docker-images/jupyter/swan-cern:${VERSION_PARENT}

LABEL maintainer="swan-admins@cern.ch"
ARG BUILD_TAG=daily
ENV VERSION_DOCKER_IMAGE=$BUILD_TAG

USER root

# For CVMFS prefetcher container
RUN dnf install -y cronie && \
    dnf clean all && \
    rm -rf /var/cache/dnf