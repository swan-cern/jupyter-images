ARG VERSION_PARENT=v0.0.4

FROM gitlab-registry.cern.ch/swan/docker-images/jupyter/swan-cern:${VERSION_PARENT}

LABEL maintainer="swan-admins@cern.ch"
ARG NB_UID="1000"
ARG BUILD_TAG=daily
ENV VERSION_DOCKER_IMAGE=$BUILD_TAG
ENV ACCPY_INSTALLER=acc-py-pro-installer

RUN echo "Building swan-accpy image with tag ${VERSION_DOCKER_IMAGE} from parent tag ${VERSION_PARENT}."

USER root

RUN wget http://bewww.cern.ch/ap/acc-py/installers/${ACCPY_INSTALLER}.sh -q && \
    chmod +x ${ACCPY_INSTALLER}.sh && \
    ./${ACCPY_INSTALLER}.sh --installation-root /opt/acc-py && \
    rm -f ${ACCPY_INSTALLER}.sh

USER ${NB_UID}
