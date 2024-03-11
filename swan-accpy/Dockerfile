ARG VERSION_PARENT=v0.0.4

FROM gitlab-registry.cern.ch/swan/docker-images/jupyter/swan-cern:${VERSION_PARENT}

LABEL maintainer="swan-admins@cern.ch"
ARG NB_UID="1000"
ARG BUILD_TAG=daily
ENV VERSION_DOCKER_IMAGE=$BUILD_TAG
ENV ACCPY_INSTALLER_2020=acc-py-2020.11-installer.sh
ENV ACCPY_INSTALLER_2021=acc-py-2021.12-installer.sh
ENV ACCPY_INSTALLER_2023=acc-py-2023.06-installer.sh
ENV INSTALLATION_ARGS="--installation-root /opt/acc-py"

RUN echo "Building swan-accpy image with tag ${VERSION_DOCKER_IMAGE} from parent tag ${VERSION_PARENT}."

USER root

RUN wget http://bewww.cern.ch/ap/acc-py/installers/${ACCPY_INSTALLER_2020} http://bewww.cern.ch/ap/acc-py/installers/${ACCPY_INSTALLER_2021} http://bewww.cern.ch/ap/acc-py/installers/${ACCPY_INSTALLER_2023} -q && \
    chmod +x ${ACCPY_INSTALLER_2020} ${ACCPY_INSTALLER_2021} ${ACCPY_INSTALLER_2023} && \
    ./${ACCPY_INSTALLER_2020} ${INSTALLATION_ARGS} && ./${ACCPY_INSTALLER_2021} ${INSTALLATION_ARGS} && ./${ACCPY_INSTALLER_2023} ${INSTALLATION_ARGS} && \
    rm -f ${ACCPY_INSTALLER_2020} ${ACCPY_INSTALLER_2021} ${ACCPY_INSTALLER_2023}

RUN dnf install -y \
    # java-1.8.0-openjdk.x86_64 \
    java-11-openjdk.x86_64 && \
    # java-17-openjdk.x86_64 \
    # java-21-openjdk.x86_64 && \
    dnf clean all && \
    rm -rf /var/cache/dnf

USER ${NB_UID}
