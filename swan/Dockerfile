# Author: Danilo Piparo, Enric Tejedor, Pedro Maximino, Diogo Castro 2023
# Copyright CERN
# This installs the SWAN packages to enable 
# using Jupyter with EOS and CVMFS

FROM gitlab-registry.cern.ch/swan/docker-images/jupyter/base:v0.0.1

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
    # Required by before-notebook scripts
    bc \
    # Required for key4hep
    environment-modules \
    git \
    # Useful to monitor resource consumption
    htop \
    nano \
    patch \
    unzip \
    which \
    # Texlive and fontconfig packages are used to convert 
    # notebooks into different formats
    texlive \
    fontconfig && \
    # Clear the dnf cache as we no longer need to install packages
    dnf clean all && \
    rm -rf /var/cache/dnf

# Install HEP_OSlibs
# This installs system packages for LCGs to work
RUN dnf -y install https://linuxsoft.cern.ch/wlcg/el9/x86_64/wlcg-repo-1.0.0-1.el9.noarch.rpm
RUN dnf -y install HEP_OSlibs-9.1.0-2.el9

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
RUN tlmgr install \
    adjustbox \
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
    swancontents==2.1.0 \
    swanhelp==3.0.2 \
    swankernelenv==1.0.0 \
    swanoauthrenew==1.0.1  \
    swanshare==2.0.0

RUN pip install \ 
    # Required dependency for swanoauthrenew
    PyJWT

# Add Python 3 kernel configuration
RUN mkdir -p /home/${NB_USER}/.local/share/jupyter/kernels/python3
ADD config/kernel.json  /home/${NB_USER}/.local/share/jupyter/kernels/python3/kernel.json

# Python configuration
# Add jupyter notebook configuration
ADD python/jupyter_server_config.py /home/${NB_USER}/.jupyter/jupyter_server_config.py

USER root

# Expose swankernelenv to the user environment in notebooks.
# swankernelenv removes the swan/extensions directory from the PYTHONPATH
# when the notebook starts. Check EOF of userconfig.sh
RUN mkdir -p /usr/local/lib/swan/extensions && \
    ln -s $(pip show swankernelenv | grep 'Location:' | awk '{print $2}')/swankernelenv /usr/local/lib/swan/extensions/

# User session configuration scripts
# Add scripts
COPY scripts/before-notebook.d/* /usr/local/bin/before-notebook.d/

# Grant scripts execution permissions
RUN chmod +x /usr/local/bin/before-notebook.d/*

# Add python scripts
ADD python/configure_kernels_and_terminal.py /srv/singleuser/configure_kernels_and_terminal.py

# Add scripts that are not executed automatically but are
# instead called by our scripts internally
RUN mkdir /srv/singleuser/scripts
COPY scripts/others/* /srv/singleuser/scripts

# Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}