# This installs the SWAN packages to enable 
# using Jupyter with EOS and CVMFS

# FROM gitlab-registry.cern.ch/swan/docker-images/notebook
FROM gitlab-registry.cern.ch/pesteves/imageregistry:notebook

LABEL maintainer="swan-admins@cern.ch"
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
    # Required by ROOT
    libXft \
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
    # Extensions required by jupyter server
    'aiohttp==3.9.0' \
    'panel==1.3.2' \
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

# Required by jupyter-resource-usage
RUN pip install --no-deps --no-cache-dir psutil==5.8.0

# Install all of our extensions
# Ignore (almost all) dependencies because they have already been installed or come from CVMFS
# RUN pip install --no-deps --no-cache-dir \
#    jupyter-resource-usage==0.6.0 \
#    swancontents==1.4.2 \
#    swanhelp==2.0.2 \
#    swanintro==1.0.0 \
#    swankernelenv==1.0.0 \
#    swannotebookviewer==1.2.0 \
#    swannotifications==1.0.0 \
#    swanoauthrenew==1.0.1 PyJWT \
#    swanshare==1.1.1 \
#    swanportallocator==1.0.1

# Python configuration
# Add jupyter notebook configuration
ADD python/jupyter_server_config.py /srv/singleuser/jupyter_server_config.py

# User session configuration scripts
# Add scripts
COPY scripts/before-notebook.d/* /usr/local/bin/before-notebook.d
ADD scripts/03_userconfig.sh /tmp

USER root
# Grant scripts execution permissions
RUN chmod +x /usr/local/bin/before-notebook.d/*

# Add python scripts
ADD python/configure_kernels_and_terminal.py /srv/singleuser/configure_kernels_and_terminal.py

# TODO: Confirm that we can remove the python script below
ADD python/start_ipykernel.py /usr/local/bin/start_ipykernel.py
RUN chmod 705 /usr/local/bin/start_ipykernel.py

# Add kernel configuration
ADD config/kernel.json /srv/singleuser/kernel.json

# Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}