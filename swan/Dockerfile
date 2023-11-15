# Installs the extensions and packages required by SWAN
# to adapt the base alma9 notebook image to SWAN.

# FROM gitlab-registry.cern.ch/swan/docker-images/notebook
FROM gitlab-registry.cern.ch/pesteves/imageregistry:notebook

LABEL maintainer="swan-admins@cern.ch"
ARG NB_USER="jovyan"
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

# Disable requiretty and secure path - required by systemuser.sh
RUN sed -i'' '/Defaults \+requiretty/d'  /etc/sudoers && \
    sed -i'' '/Defaults \+secure_path/d' /etc/sudoers

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
    perl-CGI \
    perl-ExtUtils-MakeMaker \
    perl-Test-Simple \
    perl-devel \
    rsyslog \
    time \
    xz-lzma-compat \
    # Required by Geant4 (libXm)
    openmotif \
    # Required by Oracle
    libaio \
    # Required for key4hep
    environment-modules && \
    # Clear the dnf cache as we no longer need to install packages
    dnf clean all && \
    rm -rf /var/cache/dnf

# Install python pip packages
RUN mamba install --yes \
    'jupyter_nbextensions_configurator' \
    'voila'

# Install a newer version of TeX Live, than the one available in dnf repos
# For converting to PDF
# ENV PATH /usr/local/texlive/2023/bin/x86_64-linux/:${PATH}
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
RUN pip install --no-deps --no-cache-dir \
    dask-labextension==6.1.0 \
    jupyter-resource-usage==0.6.0 \
    hdfsbrowser==1.1.1 \
    sparkconnector==2.4.6 \
    sparkmonitor==2.1.1 \
    swancontents==1.4.2 \
    swanhelp==2.0.2 \
    swanintro==1.0.0 \
    swankernelenv==1.0.0 \
    swannotebookviewer==1.2.0 \
    swannotifications==1.0.0 \
    swanoauthrenew==1.0.1 PyJWT \
    swanshare==1.1.1 \
    swanheader==1.0.0 \
    swanportallocator==1.0.1
            
# swandask must be installed after its dependency dask-labextension to disable the server extension automatically
RUN pip install --no-deps --no-cache-dir swandask==0.0.3

# Python configuration
# Add jupyter notebook configuration
ADD python/jupyter_notebook_config.py ${JUPYTER_CONFIG_DIR}/jupyter_notebook_config.py

# TODO: Review
# Enable all the nbextensions and server extensions
RUN jupyter nbextension install --py --system hdfsbrowser && \
    jupyter nbextension install --py --system sparkconnector && \
    jupyter nbextension install --py --system sparkmonitor && \
    jupyter nbextension enable --py --system sparkmonitor && \
    jupyter nbextension install --py --system swancontents && \
    jupyter serverextension enable --py --system swancontents && \
    jupyter nbextension install --py --system swanhelp && \
    jupyter nbextension enable --py --system swanhelp && \
    jupyter nbextension install --py --system swanintro && \
    jupyter nbextension enable --py --system swanintro && \
    jupyter serverextension enable --py --system swannotebookviewer && \
    jupyter nbextension install --py --system swannotifications && \
    jupyter nbextension enable --py --system swannotifications && \
    jupyter serverextension enable --py --system swanoauthrenew && \
    jupyter nbextension install --py --system swanshare && \
    jupyter nbextension enable --py --system swanshare && \
    jupyter serverextension enable --py --system swanshare && \
    jupyter serverextension enable --py --system swanportallocator && \
    # Force nbextension_configurator systemwide to prevent users disabling it
    jupyter nbextensions_configurator enable --system && \
    # FIXME workaround for templates. For some reason, and only in our image, Jupyter is looking for templates inside templates
    cp -r /opt/conda/lib/python3.11/site-packages/swancontents/templates{,2} && \
    mv /opt/conda/lib/python3.11/site-packages/swancontents/templates{2,/templates}

# Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}

ENV SHELL=/bin/bash

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
