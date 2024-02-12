#!/bin/bash

# Author: Rodrigo Sobral 2023
# Copyright CERN
# Here the script is used to create a virtual environment and install the packages from a requirements file.

_log () {
    if [[ "$*" == "ERROR:"* ]] || [[ "$*" == "WARNING:"* ]] || [[ "${JUPYTER_DOCKER_STACKS_QUIET}" == "" ]]; then
        echo "$@"
    fi
}

# This script gets two arguments:
# $1 is the name of the virtualenv (or -h in case of help page)
# $2 is the path to the requirements file to install in the virtualenv
NAME_ENV=$1
REQ_PATH=$2

# Help page
if [ "$NAME_ENV" = "-h" ]; then
    _log "This script builds a virtual environment."
    _log "Usage: makenv <virtualenv_name> <requirements_file>"
    _log "Options:"
    _log "  -h: Display this help message"
    exit 1
fi

# Checks if a name for the environment is given
if [ -z "$NAME_ENV" ]; then
    _log "ERROR: No virtual environment name provided."
    exit 0
fi

# Checks if a requirements file is given
if [ -z "$REQ_PATH" ]; then
    _log "ERROR: No requirements file provided."
    exit 0
fi

# Checks if the requirements file is found
if [ ! -f "$REQ_PATH" ]; then
    _log "ERROR: Requirements file not found."
    exit 0
fi

# Checks if an environment with the same name was already created
if [ -d "/home/$USER/${NAME_ENV}" ]; then
    _log "ERROR: Virtual environment already exists. Skipping..."
    exit 0
fi

# Create virtual environment using Python venv
_log "WARNING: Creating ${NAME_ENV} virtual environment..."

python3 -m venv /home/$USER/${NAME_ENV}

# Activate the created virtual environment
_log "WARNING: Activating virtual environment..."

source /home/$USER/${NAME_ENV}/bin/activate

# Install kernel (within the environment), so it can be ran in Jupyter 
/home/$USER/${NAME_ENV}/bin/python3 -m ipykernel install --name ${NAME_ENV} --display-name "Python (${NAME_ENV})" --prefix /home/$USER/.local

# Configure venv kernel so Jupyter can recognise it as a proper Python language
/home/$USER/${NAME_ENV}/bin/python3 -I /srv/singleuser/configure_kernels_and_terminal.py

# Install the given requirements
_log "WARNING: Installing packages from ${REQ_PATH}..."

/home/$USER/${NAME_ENV}/bin/python3 -m pip install -r ${REQ_PATH}
