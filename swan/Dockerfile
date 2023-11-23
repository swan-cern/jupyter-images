# Installs the extensions and packages required by SWAN
# to adapt the base alma9 notebook image to SWAN.

# FROM gitlab-registry.cern.ch/swan/docker-images/notebook
FROM gitlab-registry.cern.ch/pesteves/imageregistry:notebook

LABEL maintainer="swan-admins@cern.ch"
ARG NB_UID="1000"
ARG BUILD_TAG=daily
ENV VERSION_DOCKER_IMAGE=$BUILD_TAG

RUN echo "Building systemuser image with tag ${VERSION_DOCKER_IMAGE}"

# Switch to superuser to install packages
USER root

# Install required dnf packages
RUN dnf install -y  git \
   # gcc \
   # gcc-c++ \
   # kernel-devel \
   # libcurl-openssl-devel \  -- Does not exist in dnf repos
   # libffi-devel \
   # ncurses-devel \
    nano \
    nodejs \
    patch \
   # sqlite-devel \
    unzip \
    which \
   # zeromq3-devel \ -- Does not exist in dnf repos
    perl-Digest-MD5 \
    texlive \
    fontconfig

# Install HEP_OSlibs
# This installs system packages for LCGs to work
RUN dnf -y install https://linuxsoft.cern.ch/wlcg/el9/x86_64/wlcg-repo-1.0.0-1.el9.noarch.rpm
RUN dnf -y install HEP_OSlibs-9.1.0-2.el9

# TODO: Move spark related packages to the third image

# Install required packages
RUN dnf install -y \
    # Required by ROOT
    libXft \
    # Required by matplotlib
    tk \
    # Useful to monitor resource consumption
    htop \
    # Install Cloudera dependencies - required by IT Spark clusters
    alsa-lib \
    at \
    bc \
    cronie \
    cvs \
    # db4-cxx \ -- Is not present in DNF repos.
    # db4-devel \ -- Is not present in DNF repos.
    file \
    gdbm-devel \
    gettext \
    jpackage-utils \
    libXtst \
    man \
    passwd \
    # pax \ -- Is not present in DNF repos.
    # perl-CGI \
    # perl-ExtUtils-MakeMaker \
    # perl-Test-Simple \
    # perl-devel \
    rsyslog \
    time \
    xz-lzma-compat \
    # Required by Geant4 (libXm)
    openmotif \
    # Required by Oracle
    # TODO: Move to third image: libaio \
    # Required for key4hep
    environment-modules && \
    # Clear the dnf cache as we no longer need to install packages
    dnf clean all && \
    rm -rf /var/cache/dnf

# Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}

# Install python pip packages
RUN mamba install --yes \
    'jupyter_nbextensions_configurator' \
    'voila'

# Install TeX Live required packages
RUN tlmgr install adjustbox \
    tcolorbox \
    environ \
    trimspaces \
    adjustbox \
    collectbox \
    ucs \
    titling \
    enumitem \
    type1cm \
    cm-super \
    collection-fontsrecommended

# Required by jupyter-resource-usage
RUN pip install --no-deps --no-cache-dir psutil==5.8.0

# Install all of our extensions
# Ignore (almost all) dependencies because they have already been installed or come from CVMFS
# RUN pip install --no-deps --no-cache-dir \
# TODO: 3rd image   dask-labextension==6.1.0 \
#    jupyter-resource-usage==0.6.0 \
# TODO: 3rd image   hdfsbrowser==1.1.1 \
# TODO: 3rd image   sparkconnector==2.4.6 \
# TODO: 3rd image  sparkmonitor==2.1.1 \
#    swancontents==1.4.2 \
#    swanhelp==2.0.2 \
#    swanintro==1.0.0 \
#    swankernelenv==1.0.0 \
#    swannotebookviewer==1.2.0 \
#    swannotifications==1.0.0 \
#    swanoauthrenew==1.0.1 PyJWT \
#    swanshare==1.1.1 \
#    swanportallocator==1.0.1
            
# swandask must be installed after its dependency dask-labextension to disable the server extension automatically
RUN pip install --no-deps --no-cache-dir swandask==0.0.3

# Python configuration
# Add jupyter notebook configuration
ADD python/jupyter_swan_config.py /srv/singleuser/jupyter_swan_config.py

# User session configuration scripts
# Add scripts
COPY scripts /usr/local/bin/start-notebook.d

USER root
# Grant scripts execution permissions
RUN chmod +x /usr/local/bin/start-notebook.d/*

# Add python scripts
ADD python/configure_kernels_and_terminal.py /srv/singleuser/configure_kernels_and_terminal.py
ADD python/start_ipykernel.py /usr/local/bin/start_ipykernel.py
RUN chmod 705 /usr/local/bin/start_ipykernel.py

# Add js and json files
ADD js/custom.js ${CUSTOM_JS_DIR}/custom.js

# Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}
