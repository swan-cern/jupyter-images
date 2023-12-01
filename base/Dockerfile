FROM gitlab-registry.cern.ch/linuxsupport/alma9-base:20231101-1

LABEL maintainer="swan-admins@cern.ch"
ARG NB_USER="jovyan"
ARG NB_UID="1000"
ARG NB_GID="100"

# Package and software versions
ARG PYTHON_VERSION=3.11

# Fix: https://github.com/hadolint/hadolint/wiki/DL4006
# Fix: https://github.com/koalaman/shellcheck/wiki/SC3014
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# DNF should fail to install packages if there are missing names
RUN echo "skip_missing_names_on_install=False" >> /etc/dnf/dnf.conf

# ------------------------------------
#       DOCKER STACKS FOUNDATION
# ------------------------------------

# This part of the base image is based on the upstream docker-stacks-foundation
# image, available GitHub: 
# https://github.com/jupyter/docker-stacks/tree/00a67281613254de8a253a292313eb7187c83982/images/docker-stacks-foundation
# This image is the base image of the base-notebook one, and we decided to merge
# them into one single image in this Dockerfile.

USER root

# Install all OS dependencies and additional packages for Server that starts
# but lacks all features (e.g., download as all possible file formats)
RUN dnf update -y && \
    # - dnf upgrade is run to patch known vulnerabilities in dnf packages
    dnf upgrade -y && \
    # - enable Extra Packages for Enterprise Linux (EPEL) repository (CRB) 
    #   to be able to install additional packages
    dnf install -y 'dnf-command(config-manager)' && \
    dnf config-manager --set-enabled crb && \
    # EPEL package needs to install first, so that we can install tini
    # and pandoc afterwards
    dnf install -y epel-release && \
    # - bzip2 is necessary to extract the micromamba executable.
    dnf install -y bzip2 \
    sudo \
    # - tini is installed as a helpful container entrypoint that reaps zombie
    #   processes and such of the actual executable we want to start, see
    #   https://github.com/krallin/tini#why-tini for details.
    tini \
    wget

# We do not clean the dnf cache because we do it in the last image, as we
# expect the images to be squashed.

# Configure environment
ENV CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    NB_USER="${NB_USER}" \
    NB_UID=${NB_UID} \
    NB_GID=${NB_GID} \
    PYTHONIOENCODING=UTF-8
ENV PATH="${CONDA_DIR}/bin:${PATH}" \
    HOME="/home/${NB_USER}"

# Copy a script that we will use to correct permissions after running certain commands
COPY fix-permissions /usr/local/bin/fix-permissions
RUN chmod a+rx /usr/local/bin/fix-permissions

# Enable prompt color in the skeleton .bashrc before creating the default NB_USER
# Such setting has no effect in alma9, since /etc/skel/.bashrc does not have any
# logic to enable prompt color
# hadolint ignore=SC2016
RUN sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc && \
   # Add call to conda init script see https://stackoverflow.com/a/58081608/4413446
   echo 'eval "$(command conda shell.bash hook 2> /dev/null)"' >> /etc/skel/.bashrc

# Create NB_USER with name jovyan user with UID=1000 and in the 'users' group
# and make sure these dirs are writable by the `users` group.
RUN echo "auth requisite pam_deny.so" >> /etc/pam.d/su && \
    sed -i.bak -e 's/^%admin/#%admin/' /etc/sudoers && \
    sed -i.bak -e 's/^%sudo/#%sudo/' /etc/sudoers && \
    useradd --no-log-init --create-home --shell /bin/bash --uid "${NB_UID}" --no-user-group "${NB_USER}" && \
    mkdir -p "${CONDA_DIR}" && \
    chown "${NB_USER}:${NB_GID}" "${CONDA_DIR}" && \
    chmod g+w /etc/passwd && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# Change to jovyan user
USER ${NB_UID}

# Setup work directory for backward-compatibility
RUN mkdir "/home/${NB_USER}/work" && \
    fix-permissions "/home/${NB_USER}"

# Download and install Micromamba, and initialize Conda prefix.
#   <https://github.com/mamba-org/mamba#micromamba>
#   Similar projects using Micromamba:
#     - Micromamba-Docker: <https://github.com/mamba-org/micromamba-docker>
#     - repo2docker: <https://github.com/jupyterhub/repo2docker>
# Install Python, Mamba and jupyter_core
# Cleanup temporary files and remove Micromamba
# Correct permissions
# Do all this in a single RUN command to avoid duplicating all of the
# files across image layers when the permissions change
COPY --chown="${NB_UID}:${NB_GID}" initial-condarc "${CONDA_DIR}/.condarc"
WORKDIR /tmp
RUN set -x && \
    arch=$(uname -m) && \
    if [ "${arch}" = "x86_64" ]; then \
        # Should be simpler, see <https://github.com/mamba-org/mamba/issues/1437>
        arch="64"; \
    fi && \
    # curl is used instead of wget, as we get a 403 Forbidden error while downloading
    # micromamba only when using the later command.
    curl -L -o /tmp/micromamba.tar.bz2 \
        "https://micromamba.snakepit.net/api/micromamba/linux-${arch}/latest" && \
    tar -xvjf /tmp/micromamba.tar.bz2 --strip-components=1 bin/micromamba && \
    rm /tmp/micromamba.tar.bz2 && \
    PYTHON_SPECIFIER="python=${PYTHON_VERSION}" && \
    if [[ "${PYTHON_VERSION}" == "default" ]]; then PYTHON_SPECIFIER="python"; fi && \
    # Install the packages
    ./micromamba install \
        --root-prefix="${CONDA_DIR}" \
        --prefix="${CONDA_DIR}" \
        --yes \
        "${PYTHON_SPECIFIER}" \
        'mamba' \
        'jupyter_core' && \
    rm micromamba && \
    # Pin major.minor version of python
    mamba list python | grep '^python ' | tr -s ' ' | cut -d ' ' -f 1,2 >> "${CONDA_DIR}/conda-meta/pinned" && \
    mamba clean --all -f -y && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# Configure container startup
ENTRYPOINT ["tini", "-g", "--"]

# Copy local files as late as possible to avoid cache busting
COPY run-hooks.sh start.sh /usr/local/bin/

USER root

# Create dirs for startup hooks
RUN mkdir /usr/local/bin/start-notebook.d && \
    mkdir /usr/local/bin/before-notebook.d

# ------------------------------------
#            BASE NOTEBOOK
# ------------------------------------

# This part of the base image is based on the upstream base-notebook
# image and files, available GitHub: 
# https://github.com/jupyter/docker-stacks/tree/0d8b4e498766fb451e3ba08f9ade9da344db5d83/images/base-notebook

# Install all base notebook dependencies
RUN dnf install -y pandoc

# Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}

# Install JupyterLab, Jupyter Notebook, JupyterHub and NBClassic
# Generate a Jupyter Server config
# Cleanup temporary files
# Correct permissions
# Do all this in a single RUN command to avoid duplicating all of the
# files across image layers when the permissions change
# Force the current latest versions of the python packages installed
# in the SWAN base image, except for the notebook one. This package
# is using the latest version (6.5.6) before major version 7, as there
# are incompatibility issues that arise due to the usage of such
# version along with the package nbclassic or swanclassic.
WORKDIR /tmp
RUN mamba install --yes \
    'jupyterlab==4.0.7' \
    'notebook==6.5.6' \
    'jupyterhub==4.0.2' \
    'nbclassic==1.0.0' && \
    jupyter server --generate-config && \
    mamba clean --all -f -y && \
    npm cache clean --force && \
    jupyter lab clean && \
    rm -rf "/home/${NB_USER}/.cache/yarn" && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

ENV JUPYTER_PORT=8888
EXPOSE $JUPYTER_PORT

# Configure container startup
CMD ["start-notebook.sh"]

# Copy local files as late as possible to avoid cache busting
COPY start-notebook.sh start-singleuser.sh /usr/local/bin/
COPY jupyter_server_config.py docker_healthcheck.py /etc/jupyter/

# Fix permissions on /etc/jupyter as root
USER root
RUN fix-permissions /etc/jupyter/

# Grant execution permissions to shell script files
RUN chmod +x /usr/local/bin/start-notebook.sh && \
    chmod +x /usr/local/bin/start-singleuser.sh && \
    chmod +x /usr/local/bin/run-hooks.sh && \
    chmod +x /usr/local/bin/start.sh

# HEALTHCHECK documentation: https://docs.docker.com/engine/reference/builder/#healthcheck
# This healtcheck works well for `lab`, `notebook`, `nbclassic`, `server` and `retro` jupyter commands
# https://github.com/jupyter/docker-stacks/issues/915#issuecomment-1068528799
HEALTHCHECK --interval=5s --timeout=3s --start-period=5s --retries=3 \
    CMD /etc/jupyter/docker_healthcheck.py || exit 1

# Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}
WORKDIR "${HOME}"

# ------------------------------------
#               SWAN
# ------------------------------------

# This part of the base image contains SWAN specific customizations
# and python packages.

RUN pip install --no-cache-dir swanheader==2.0.1

# This disables the Jupyter project communication warnings that appear in the UI.
# Users cannot do anything about it (i.e update Jupyter), so it's better to hide it.
RUN jupyter labextension disable "@jupyterlab/apputils-extension:announcements"
USER root

# This setting disables the creation of the home directory for
# new users, which is enabled by default. It is needed, so that
# the start.sh script is able to create the directory and copy
# the files from jovyan to the new user home.
# It is required because this is the default behaviour in ubuntu
# but not in AlmaLinux 9.
RUN sed -i 's/CREATE_HOME.*/CREATE_HOME 0/g' /etc/login.defs

# Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}
