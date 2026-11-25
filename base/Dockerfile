FROM gitlab-registry.cern.ch/linuxsupport/alma9-base:20261116-1 as root_image

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

# Micromamba is taken from the official image, pinned by digest for integrity
# Dependabot keeps this version and digest up to date (`docker` ecosystem covers this directory)
# The binary is bind-mounted into the install RUN below, so it is not added to any image layer
FROM docker.io/mambaorg/micromamba:2.10.0@sha256:e1476182cd40eb1f7c0cfae4adec9bfd78f3d7f05c61368306abfdc8939c1198 AS micromamba

FROM root_image

USER root

# Install all OS dependencies and additional packages for Server that starts
# but lacks all features (e.g., download as all possible file formats)
RUN dnf update -y && \
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

# We do not clean the dnf cache because we do it at the end of this Dockerfile, as we
# expect this image to be squashed.

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
    # More information in: https://github.com/jupyter/docker-stacks/pull/2047
    # and docs: https://docs.conda.io/projects/conda/en/latest/dev-guide/deep-dives/activation.html
    echo 'eval "$(conda shell.bash hook)"' >> /etc/skel/.bashrc

# Create "${NB_USER}" user (`jovyan` by default) with UID="${NB_UID}" (`1000` by default) and in the 'users' group
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

# Install the Conda prefix using Micromamba from the digest-pinned official image (see top of this file).
#   <https://github.com/mamba-org/mamba#micromamba>
#   Similar projects using Micromamba:
#     - Micromamba-Docker: <https://github.com/mamba-org/micromamba-docker>
#     - repo2docker: <https://github.com/jupyterhub/repo2docker>
# Install Python, Mamba, and jupyter_core
# Cleanup temporary files
# Correct permissions
# Do all this in a single RUN command to avoid duplicating all of the
# files across image layers when the permissions change
COPY --chown="${NB_UID}:${NB_GID}" initial-condarc "${CONDA_DIR}/.condarc"
WORKDIR /tmp
RUN --mount=type=bind,from=micromamba,source=/bin/micromamba,target=/usr/local/bin/micromamba \
    set -x && \
    PYTHON_SPECIFIER="python=${PYTHON_VERSION}" && \
    if [ "${PYTHON_VERSION}" = "default" ]; then PYTHON_SPECIFIER="python"; fi && \
    # Install the packages
    micromamba install \
        --root-prefix="${CONDA_DIR}" \
        --prefix="${CONDA_DIR}" \
        --yes \
        'jupyter_core=5.9.1' \
        'conda' \
        # Install mamba with the same version as the micromamba image pinned above
        # (they are released together)
        "mamba==$(micromamba --version)" \
        "${PYTHON_SPECIFIER}" && \
    # Pin major.minor version of python
    # https://conda.io/projects/conda/en/latest/user-guide/tasks/manage-pkgs.html#preventing-packages-from-updating-pinning
    mamba list --full-name 'python' | awk 'END{sub("[^.]*$", "*", $2); print $1 " " $2}' >> "${CONDA_DIR}/conda-meta/pinned" && \
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
RUN dnf install -y pandoc && \
    dnf clean all && \
    rm -rf /var/cache/dnf

# Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}

# Install JupyterHub, JupyterLab, NBClassic and Jupyter Notebook
# Generate a Jupyter Server config
# Cleanup temporary files
# Correct permissions
# Do all this in a single RUN command to avoid duplicating all of the
# files across image layers when the permissions change
# Force the current latest versions of the python packages installed
# in the SWAN base image.
# tornado 6.5.8 is pinned to avoid extension load errors
# via symlinks not allowed from 6.5.9
WORKDIR /tmp
RUN mamba install --yes \
    'tornado==6.5.8' \
    'jupyterhub-singleuser==5.4.3' \
    'jupyterlab==4.5.6' \
    'nbclassic==1.3.3' \
    # Sometimes, when the new version of `jupyterlab` is released, latest `notebook` might not support it for some time
    # Old versions of `notebook` (<v7) didn't have a restriction on the `jupyterlab` version, and old `notebook` is getting installed
    # That's why we have to pin the minimum notebook version
    # More info: https://github.com/jupyter/docker-stacks/pull/2167
    'notebook>=7.2.2' && \
    jupyter server --generate-config && \
    mamba clean --all -f -y && \
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

RUN pip install --no-cache-dir swanheader==2.0.4

# This disables the Jupyter project communication warnings that appear in the UI.
# Users cannot do anything about it (i.e update Jupyter), so it's better to hide it.
RUN jupyter labextension disable "@jupyterlab/apputils-extension:announcements"
# Disable the built-in interface switcher. We want to keep the JupyterLab UI separate from the classic one
RUN jupyter labextension disable "@jupyter-notebook/lab-extension:interface-switcher"
USER root

# This setting disables the creation of the home directory for
# new users, which is enabled by default. It is needed, so that
# the start.sh script is able to create the directory and copy
# the files from jovyan to the new user home.
# It is required because this is the default behaviour in ubuntu
# but not in AlmaLinux 9.
RUN sed -i 's/^CREATE_HOME.*/CREATE_HOME 0/g' /etc/login.defs

# Remove the warning when running `useradd` about the UID being 
# outside of the allowed range
RUN sed -i 's/^UID_MAX.*/UID_MAX 100000/g' /etc/login.defs

# Remove warning about creation of the mailbox when running `useradd`
RUN sed -i 's/^CREATE_MAIL_SPOOL.*/CREATE_MAIL_SPOOL=no/g' /etc/default/useradd

# Prevent warning about not being able to debug frozen modules.
# More information here:
# - https://stackoverflow.com/questions/75114841/debugger-warning-from-ipython-frozen-modules
# - https://discourse.jupyter.org/t/debugger-warning-it-seems-that-frozen-modules-are-being-used-python-3-11-0/16544/5
ENV PYDEVD_DISABLE_FILE_VALIDATION=1

# By default, prevent the lookup of Python modules in the user site by:
# - The Jupyter server
# - Python notebook processes
# - Python processes created in the terminal
ENV PYTHONNOUSERSITE=1

# Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}
