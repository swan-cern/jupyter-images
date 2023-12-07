ARG VERSION_PARENT=v0.0.1

FROM gitlab-registry.cern.ch/swan/docker-images/jupyter/swan:${VERSION_PARENT}

LABEL maintainer="swan-admins@cern.ch"
ARG NB_UID="1000"
ARG BUILD_TAG=daily
ENV VERSION_DOCKER_IMAGE=$BUILD_TAG

RUN echo "Building swan-cern image with tag ${VERSION_DOCKER_IMAGE} from parent tag ${VERSION_PARENT}."

# Switch to superuser to install packages
USER root

RUN dnf install -y \
    # Install Cloudera dependencies - required by IT Spark clusters
    alsa-lib \
    at \
    cronie \
    cvs \
    file \
    gdbm-devel \
    gettext \
    jpackage-utils \
    libXtst \
    man \
    passwd \
    rsyslog \
    time \
    xz-lzma-compat \
    # Required by Oracle
    libaio && \
    # Clear the dnf cache as we no longer need to install packages
    dnf clean all && \
    rm -rf /var/cache/dnf

# Configure Dask
# Set Dask environment
ENV DASK_DIR=/srv/dask
ENV DASK_LIB_DIR=${DASK_DIR}/lib
ENV DASK_TLS_DIR=${DASK_DIR}/tls

RUN mkdir -p ${DASK_LIB_DIR} ${DASK_TLS_DIR} && \
    fix-permissions ${DASK_LIB_DIR} && \
    chown -R ${NB_USER}:${NB_GID} ${DASK_TLS_DIR}

USER ${NB_UID}

# User session configuration scripts
# Add scripts to be run before the jupyter server starts
COPY scripts/before-notebook.d/* /usr/local/bin/before-notebook.d/

# dask-labextension needs to be installed first so its lab extension
# gets disabled automatically when installing swandask
RUN pip install --no-deps --no-cache-dir dask-labextension==7.0.0

# Install all of our extensions required to access Spark, HDFS and Dask.
# Ignore dependencies because they have already been installed or come from CVMFS
RUN pip install --no-deps --no-cache-dir \
    sparkconnector==2.4.6 \
    sparkmonitor==2.1.1 \
    swanportallocator==1.0.1 \
    swandask==0.0.3

# Install swandaskcluster in its own lib dir so that we can add it individually
# to the PYTHONPATH of notebooks and terminals, which need it to do automatic
# TLS configuration for Dask clients
RUN pip install --no-deps --no-cache-dir --target ${DASK_LIB_DIR} \
    swandaskcluster==2.0.1

# Add helper scripts
COPY scripts/others/* /srv/singleuser/

# Add dask configuration file
# Dask config: lab extension must use SwanHTCondorCluster
ADD config/dask-labextension.yaml /etc/dask/labextension.yaml

USER root

# Dependency of swandaskcluster
RUN ln -s $(pip show swanportallocator | grep -oP 'Location: \K.*')/swanportallocator ${DASK_LIB_DIR}

# Create symlinks for the remaining swan extensions, because
# they need to be accessible in the user environment
RUN ln -s $(pip show sparkconnector | grep -oP 'Location: \K.*')/sparkconnector /usr/local/lib/swan/extensions/ && \
    ln -s $(pip show sparkmonitor | grep -oP 'Location: \K.*')/sparkmonitor /usr/local/lib/swan/extensions/ && \
    ln -s $(pip show swandask | grep -oP 'Location: \K.*')/swandask /usr/local/lib/swan/extensions/ && \
    ln -s $(pip show dask-labextension | grep -oP 'Location: \K.*')/dask-labextension /usr/local/lib/swan/extensions/ && \
    ln -s $(pip show jupyter-server-proxy | grep -oP 'Location: \K.*')/jupyter_server_proxy /usr/local/lib/swan/extensions/

# Grant scripts execution permissions
RUN chmod +x /usr/local/bin/before-notebook.d/*

# Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}