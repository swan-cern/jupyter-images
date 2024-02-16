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
NAME_ENV=
REQ_PATH=
CLEAR_ENV=

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h)
            # Help page (passing -h as first argument)
            _log "
This script builds a virtual environment."
            _log "Usage: makenv <virtualenv_name> <requirements_file>"
            _log "Options:"
            _log "  -h: Display this help message"
            _log "  -c: Clear the virtual environment, if it exists (TBD)
            "
            exit 1
            ;;
        -c)
            # If -c is found, shift to next argument and store its value
            CLEAR_ENV="--clear"
            shift
            ;;
        *)
            case "requirements.txt" in
                *$1*)
                    REQ_PATH=$1
                    shift
                    ;;
                *)
                    NAME_ENV=$1
                    shift
                    ;;
            esac
    esac
done

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

# Checks if an environment with the same name was already created, if -c is not passed
if [ -d "/home/$USER/${NAME_ENV}" ] && [ -z "$CLEAR_ENV" ]; then
    _log "ERROR: Virtual environment already exists."
    exit 1
fi

PATH=$PATH
USER=$USER
OAUTH2_FILE=$OAUTH2_FILE
OAUTH2_TOKEN=$OAUTH2_TOKEN
KRB5CCNAME=$KRB5CCNAME
KRB5CCNAME_NB_TERM=$KRB5CCNAME_NB_TERM
JUPYTER_DOCKER_STACKS_QUIET=$JUPYTER_DOCKER_STACKS_QUIET

# Create a new bash session to avoid conflicts with the current environment in the background
env -i bash --noprofile --norc << EOF

export PATH=${PATH}
export USER=${USER}
export OAUTH2_FILE=${OAUTH2_FILE}
export OAUTH2_TOKEN=${OAUTH2_TOKEN}
export KRB5CCNAME=${KRB5CCNAME}
export KRB5CCNAME_NB_TERM=${KRB5CCNAME_NB_TERM}

# Create virtual environment using Python venv
if [ -z "$CLEAR_ENV" ]; then
    echo "Creating ${NAME_ENV} virtual environment..."
else
    echo "Recreating (-c) ${NAME_ENV} virtual environment..."
fi
python3 -m venv /home/$USER/${NAME_ENV} --copies ${CLEAR_ENV}

# Activate the created virtual environment
echo "Activating virtual environment..."
source /home/$USER/${NAME_ENV}/bin/activate

# Ensure pip is installed on venv so ipykernel and requirements can be installed
# python3 -m ensurepip --upgrade

# Install ipykernel so the kernel can be used in Jupyter
python3 -m pip install --upgrade -q pip
pip install ipykernel -q

# Install kernel (within the environment), so it can be ran in Jupyter 
python3 -m ipykernel install --name ${NAME_ENV} --display-name "Python (${NAME_ENV})" --prefix /home/$USER/.local

# Install the given requirements
echo "Installing packages from ${REQ_PATH}..."
pip install -q -r ${REQ_PATH}

# Copy the requirements file to the virtual environment
cp ${REQ_PATH} /home/$USER/${NAME_ENV}

echo "Virtual environment ${NAME_ENV} created successfully."
echo "WARNING: You may need to refresh the page to see the new kernel in Jupyter."
 
EOF
