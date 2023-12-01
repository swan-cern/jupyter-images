
FROM gitlab-registry.cern.ch/pesteves/imageregistry:swan-notebook.latest

LABEL maintainer="swan-admins@cern.ch"
ARG NB_UID="1000"
ARG BUILD_TAG=daily
ENV VERSION_DOCKER_IMAGE=$BUILD_TAG

RUN echo "Building swan-cern image with tag ${VERSION_DOCKER_IMAGE}"

# Switch to superuser to install packages
USER root

RUN dnf install -y \
    # Install Cloudera dependencies - required by IT Spark clusters
    alsa-lib \
    at \
    bc \
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

USER ${NB_UID}

# Install all of our extensions required to access Spark, HDFS and Dask.
# Ignore (almost all) dependencies because they have already been installed or come from CVMFS
RUN pip install --no-deps --no-cache-dir \
    dask-labextension==6.1.0 \
    sparkconnector==2.4.6 \
    sparkmonitor==2.1.1

# swandask must be installed after its dependency dask-labextension to disable
# the server extension automatically
RUN pip install --no-deps --no-cache-dir swandask==0.0.3

# Configure Dask
# Set Dask environment
ENV DASK_DIR=/srv/dask
ENV DASK_LIB_DIR=${DASK_DIR}/lib
ENV DASK_TLS_DIR=${DASK_DIR}/tls

USER root

RUN mkdir -p ${DASK_LIB_DIR} ${DASK_TLS_DIR} && \
    fix-permissions ${DASK_LIB_DIR} && \
    fix-permissions ${DASK_TLS_DIR}

USER ${NB_UID}

# Install swandaskcluster in its own lib dir so that we can add it individually
# to the PYTHONPATH of notebooks and terminals, which need it to do automatic
# TLS configuration for Dask clients
RUN pip install --no-deps --no-cache-dir --target ${DASK_LIB_DIR} \
        swandaskcluster==2.0.1

# Dependency of swandaskcluster
RUN ln -s /usr/local/lib/python3.9/site-packages/swanportallocator ${DASK_LIB_DIR}

# Add script to create dask secrets
ADD scripts/others/create_dask_secrets.sh /srv/singleuser/create_dask_secrets.sh

# User session configuration scripts
# Add scripts to be run before the jupyter server starts
COPY scripts/before-notebook.d/* /usr/local/bin/before-notebook.d

USER root

# Grant scripts execution permissions
RUN chmod +x /usr/local/bin/before-notebook.d/*

# Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}