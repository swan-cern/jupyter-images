ARG VERSION_PARENT=v0.0.3

FROM gitlab-registry.cern.ch/swan/docker-images/jupyter/swan-cern:${VERSION_PARENT}
# FROM registry.cern.ch/acc/acc-py_cc7_ci:2021.12

LABEL maintainer="swan-admins@cern.ch"
ARG NB_UID="1000"
ARG BUILD_TAG=daily
ENV VERSION_DOCKER_IMAGE=$BUILD_TAG

RUN echo "Building swan-accpy image with tag ${VERSION_DOCKER_IMAGE} from parent tag ${VERSION_PARENT}."

RUN pip install --no-cache pyjapc && python -m cmmnbuild_dep_manager resolve

ENV PACKAGES="bash bash-completion CERN-CA-certs coreutils iputils rootfiles vim-minimal yum yum-utils"

RUN dnf install -y $PACKAGES && \
    dnf clean all && \
    rm -rf /var/cache/dnf
