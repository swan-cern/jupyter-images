# Installs the extensions and packages required by SWAN
# to adapt the base alma9 notebook image to SWAN.

FROM gitlab-registry.cern.ch/swan/docker-images/notebook

LABEL maintainer="swan-admins@cern.ch"
ARG NB_USER="jovyan"
ARG NB_UID="1000"
ARG BUILD_TAG=daily
ENV VERSION_DOCKER_IMAGE=$BUILD_TAG

RUN echo "Building systemuser image with tag ${VERSION_DOCKER_IMAGE}"

# Switch to superuser to install packages
USER root

# Install required dnf packages
RUN dnf install -y gcc \
    gcc-c++ \
    git \
    kernel-devel \
   # libcurl-openssl-devel \  -- Does not exist in dnf repos
    libffi-devel \
    ncurses-devel \
    nano \
    nodejs \
    patch \
    sqlite-devel \
    unzip \
    which \
   # zeromq3-devel \ -- Does not exist in dnf repos
    perl-Digest-MD5 \
    texlive \
    fontconfig && \
    # Clear the dnf cache as we no longer need to install packages
    dnf clean all && \
    rm -rf /var/cache/dnf

# Install a newer version of TeX Live, than the one available in dnf repos
# For converting to PDF
ENV PATH /usr/local/texlive/2023/bin/x86_64-linux/:$PATH
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

# Install python pip packages
# RUN pip3 --no-cache-dir install \
#           'ipyparallel==6.3.0' \
#            'notebook==6.4.2' \
#            'jupyterhub==4.0.2' \
#            'urllib3==1.26.16' \
#            'jupyterlab==3.0.17' \
#            'jupyter_nbextensions_configurator' \
#            'voila'

# Install python pip packages
RUN mamba install --yes \
    'jupyter_nbextensions_configurator' \
    'voila'

VOLUME /notebooks
WORKDIR /notebooks

CMD ["jupyter", "notebook"]

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
    environment-modules 

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
    # Spark Monitor/Connector also need to be available to the user environment since they have kernel extensions
    # PortAllocator is used by SparkConnector, so it needs to be available too
    mkdir -p /usr/local/lib/swan/extensions && \
    ln -s /opt/conda/lib/python3.11/site-packages/sparkmonitor /usr/local/lib/swan/extensions/ && \
    ln -s /opt/conda/lib/python3.11/site-packages/sparkconnector /usr/local/lib/swan/extensions/ && \
    ln -s /opt/conda/lib/python3.11/site-packages/swankernelenv /usr/local/lib/swan/extensions/ && \
    ln -s /opt/conda/lib/python3.11/site-packages/swanportallocator /usr/local/lib/swan/extensions/ && \
    ln -s /opt/conda/lib/python3.11/site-packages/dask_labextension /usr/local/lib/swan/extensions/ && \
    ln -s /opt/conda/lib/python3.11/site-packages/jupyter_server_proxy /usr/local/lib/swan/extensions/ && \
    ln -s /opt/conda/lib/python3.11/site-packages/simpervisor /usr/local/lib/swan/extensions/ && \
    ln -s /opt/conda/lib/python3.11/site-packages/swandask /usr/local/lib/swan/extensions/ && \
    # FIXME workaround for templates. For some reason, and only in our image, Jupyter is looking for templates inside templates
    cp -r /opt/conda/lib/python3.11/site-packages/swancontents/templates{,2} && \
    mv /opt/conda/lib/python3.11/site-packages/swancontents/templates{2,/templates}

ENV SHELL=/bin/bash

# Set environment for the Jupyter process
ENV JPY_DIR=/home/${NB_USER}/.jupyter
ENV IPYTHONDIR=/home/${NB_USER}/.ipython
ENV JUPYTER_CONFIG_DIR=${JPY_DIR}
ENV JUPYTER_PATH=/home/${NB_USER}/.local/share/jupyter
ENV USERDATA_PATH=/srv/singleuser/userdata

# Create the iPython directory
RUN mkdir -p ${IPYTHONDIR} && \
    chown -R $USER:$USER ${IPYTHONDIR}

# Add shell scripts
ADD scripts/systemuser.sh /srv/singleuser/systemuser.sh
ADD scripts/userconfig.sh /srv/singleuser/userconfig.sh
ADD scripts/create_dask_certs.sh /srv/singleuser/create_dask_certs.sh

# Add python scripts
ADD python/configure_kernels_and_terminal.py /srv/singleuser/configure_kernels_and_terminal.py
ADD python/start_ipykernel.py /usr/local/bin/start_ipykernel.py
RUN chmod 705 /usr/local/bin/start_ipykernel.py

WORKDIR /root