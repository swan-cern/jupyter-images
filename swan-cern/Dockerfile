
FROM FROM gitlab-registry.cern.ch/pesteves/imageregistry:swan-notebook.latest

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
    libaio \
    # Clear the dnf cache as we no longer need to install packages
    dnf clean all && \
    rm -rf /var/cache/dnf

# Install all of our extensions required to access Spark, HDFS and Dask.
# Ignore (almost all) dependencies because they have already been installed or come from CVMFS
RUN pip install --no-deps --no-cache-dir \
    dask-labextension==6.1.0 \
    hdfsbrowser==1.1.1 \
    sparkconnector==2.4.6 \
    sparkmonitor==2.1.1

# swandask must be installed after its dependency dask-labextension to disable the server extension automatically
RUN pip install --no-deps --no-cache-dir swandask==0.0.3