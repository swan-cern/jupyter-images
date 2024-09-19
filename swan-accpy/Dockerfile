ARG VERSION_PARENT=v0.0.26

FROM gitlab-registry.cern.ch/swan/docker-images/jupyter/swan-cern:${VERSION_PARENT}

LABEL maintainer="swan-admins@cern.ch"
ARG NB_UID="1000"
ARG BUILD_TAG=daily
ENV VERSION_DOCKER_IMAGE=$BUILD_TAG
ENV ACCPY_PATH="/opt/acc-py"

RUN echo "Building swan-accpy image with tag ${VERSION_DOCKER_IMAGE} from parent tag ${VERSION_PARENT}."

USER root

# Install currently supported acc-py distributions
RUN for version in "2020.11" "2021.12" "2023.06"; do \
        wget http://bewww.cern.ch/ap/acc-py/installers/acc-py-${version}-installer.sh && \
        chmod +x acc-py-${version}-installer.sh && \
        ./acc-py-${version}-installer.sh --installation-root ${ACCPY_PATH} && \
        rm -f acc-py-${version}-installer.sh && \
        source ${ACCPY_PATH}/base/${version}/setup.sh && \
        ${ACCPY_PATH}/base/${version}/bin/python -m ensurepip --upgrade && \
        ${ACCPY_PATH}/base/${version}/bin/pip3 install ipykernel && \
        deactivate; \
    done

# Install Java JDK 11
RUN dnf install -y \
    java-11-openjdk.x86_64 && \
    dnf clean all && \
    rm -rf /var/cache/dnf

# Install and configure SwanCustomEnvironments extension
RUN pip install --no-deps --no-cache-dir \
    swancustomenvironments==0.0.10
RUN echo -e '\nc.ServerApp.extra_template_paths = ["/opt/conda/lib/python3.11/site-packages/swancustomenvironments/templates/"]' >> /home/${NB_USER}/.jupyter/jupyter_server_config.py

USER ${NB_UID}