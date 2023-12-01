# Author: Danilo Piparo, Enric Tejedor, Pedro Maximino, Diogo Castro 2023
# Copyright CERN
# This installs the SWAN packages to enable 
# using Jupyter with EOS and CVMFS

FROM gitlab-registry.cern.ch/pesteves/imageregistry:notebook

LABEL maintainer="swan-admins@cern.ch"

ARG NB_USER="jovyan"
ARG NB_UID="1000"
ARG BUILD_TAG=daily
ENV VERSION_DOCKER_IMAGE=$BUILD_TAG

RUN echo "Building swan image with tag ${VERSION_DOCKER_IMAGE}"

# Switch to superuser to install packages
USER root

# Install required dnf packages
RUN dnf install -y \
    git \
    nano \
    patch \
    unzip \
    which \
    texlive \
    fontconfig

# Install HEP_OSlibs
# This installs system packages for LCGs to work
RUN dnf -y install https://linuxsoft.cern.ch/wlcg/el9/x86_64/wlcg-repo-1.0.0-1.el9.noarch.rpm
RUN dnf -y install HEP_OSlibs-9.1.0-2.el9

# TODO: Move spark related packages to the third image

# Install required packages
RUN dnf install -y \
    # Required by before-notebook scripts.
    bc \
    # Useful to monitor resource consumption
    htop \
    # Required for key4hep
    environment-modules && \
    # Clear the dnf cache as we no longer need to install packages
    dnf clean all && \
    rm -rf /var/cache/dnf

# Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}

# Install python pip packages
RUN mamba install --yes \
    'jupyter_nbextensions_configurator==0.6.1' \
    'voila==0.5.5' \
    'ipyparallel==8.6.1' \
    'jupyter-server-proxy==4.1.0' \
    'jupyter-resource-usage==1.0.1' \
    # Extensions required by jupyter server
    'panel==1.3.4' \
    'webio-jupyter-extension==0.1.0'


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

# Install all of our extensions
# Ignore (almost all) dependencies because they have already been installed or come from CVMFS
RUN pip install --no-deps --no-cache-dir \
    swancontents==2.0.0 \
    swanhelp==3.0.2 \
    swankernelenv==1.0.0 \
    swanoauthrenew==1.0.1  \
    swanshare==2.0.0 \
    swanportallocator==1.0.1

# pip install required deps
RUN pip install PyJWT

# User session configuration scripts
# Add scripts
COPY scripts/before-notebook.d/* /usr/local/bin/before-notebook.d
ADD scripts/03_userconfig.sh /srv/singleuser/03_userconfig.sh

USER root

# Grant scripts execution permissions
RUN chmod +x /usr/local/bin/before-notebook.d/*

# Add python scripts
ADD python/configure_kernels_and_terminal.py /srv/singleuser/configure_kernels_and_terminal.py

# Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}

# Add Python 3 kernel configuration
RUN mkdir -p /home/${NB_USER}/.local/share/jupyter/kernels/python3
ADD config/kernel.json  /home/${NB_USER}/.local/share/jupyter/kernels/python3/kernel.json

# Python configuration
# Add jupyter notebook configuration
ADD python/jupyter_server_config.py /home/${NB_USER}/.jupyter/jupyter_server_config.py