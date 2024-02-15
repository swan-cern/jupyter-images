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

# Help page (passing -h as first argument)
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
    exit 1
fi

# Checks if a requirements file is given
if [ -z "$REQ_PATH" ]; then
    _log "ERROR: No requirements file provided."
    exit 1
fi

# Checks if the requirements file is found
if [ ! -f "$REQ_PATH" ]; then
    _log "ERROR: Requirements file not found."
    exit 1
fi

# Checks if an environment with the same name was already created
if [ -d "/home/$USER/${NAME_ENV}" ]; then
    _log "ERROR: Virtual environment already exists."
    exit 1
fi

# Create virtual environment using Python venv
_log "Creating ${NAME_ENV} virtual environment..."
python3 -m venv /home/$USER/${NAME_ENV} --copies

# Activate the created virtual environment
_log "Activating virtual environment..."
source /home/$USER/${NAME_ENV}/bin/activate

# Unset PYTHONPATH to avoid that the virtual environment uses the system packages
unset PYTHONPATH

# Ensure pip is installed on venv so ipykernel and requirements can be installed
python3 -m ensurepip --upgrade

# Install ipykernel so the kernel can be used in Jupyter
pip3 install ipykernel -q 

# Install kernel (within the environment), so it can be ran in Jupyter 
python3 -m ipykernel install --name ${NAME_ENV} --display-name "Python (${NAME_ENV})" --prefix /home/$USER/.local

# Install the given requirements
_log "Installing packages from ${REQ_PATH}..."
pip3 install -q -r ${REQ_PATH}

_log "Virtual environment ${NAME_ENV} created successfully."
_log "WARNING: You may need to refresh the page"
