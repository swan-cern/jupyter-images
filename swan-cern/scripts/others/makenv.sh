#!/bin/bash

# Author: Rodrigo Sobral 2023
# Copyright CERN
# Here the script is used to create a virtual environment and install the packages from a requirements file.

_log () {
    if [[ "$*" == "ERROR:"* ]] || [[ "$*" == "WARNING:"* ]] || [[ "${JUPYTER_DOCKER_STACKS_QUIET}" == "" ]]; then
        echo "$@"
    fi
}

# Function to print the help page
print_help() {
    _log "Usage: makenv --name NAME --req REQUIREMENTS [--clear] [--help/-h]"
    _log "Options:"
    _log "  -n, --name NAME             Name of the custom virtual environment (mandatory)"
    _log "  -r, --req REQUIREMENTS      Path to requirements.txt file or http link for a public repository (mandatory)"
    _log "  -c, --clear                 Clear the current virtual environment if it exists"
    _log "  -h, --help                  Print this help page"
}

# --------------------------------------------------------------------------------------------

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --name|-n)
            NAME_ENV=$2
            shift
            shift
            ;;
        --req|-r)
            requirements=$2
            shift
            shift
            ;;
        --clear|-c)
            CLEAR_ENV=--clear
            shift
            ;;
        --help|-h)
            print_help
            exit 0
            ;;
        *)
            _log "Invalid argument: $1"
            print_help
            exit 1
            ;;
    esac
done

# --------------------------------------------------------------------------------------------

# Checks if a name for the environment is given
if [ -z "$NAME_ENV" ]; then
    _log "ERROR: No virtual environment name provided."
    print_help
    exit 1
fi

# Checks if a requirements file is given
if [ -z "$requirements" ]; then
    _log "ERROR: No requirements provided."
    print_help
    exit 1
fi


# Checks if the provided requirements source is found
if [[ -f $requirements ]]; then
    REQ_PATH=$requirements
elif [[ $requirements == http* ]]; then
    # Extract the repository name from the URL
    repo_name=$(basename $requirements)
    repo_name=${repo_name%.*}

    cd ~
    # Checks if the repository already exists in the home directory
    if [ -d $repo_name ]; then
        if [ -z "$CLEAR_ENV" ]; then
            _log "ERROR: $PWD/$repo_name already exists. Use --clear to recreate the environment."
            exit 1
        else
            rm -rf $repo_name
        fi
    fi

    # Clone the repository
    git clone $requirements -q --template /usr/share/git-core/templates || { _log "Error: Failed to clone repository"; exit 1; }

    # Check if requirements.txt exists in the repository
    if [[ ! -f $repo_name/requirements.txt ]]; then
        rm -rf $repo_name
        _log "Error: requirements.txt not found in the repository"
        exit 1
    fi

    # Set the requirements path to the cloned repository
    REQ_PATH=$PWD/$repo_name/requirements.txt
else
    _log "ERROR: Requirements not found."
    exit 1
fi

# Checks if an environment with the same name was already created, if --clear is not passed
if [ -d "/home/$USER/${NAME_ENV}" ] && [ -z "$CLEAR_ENV" ]; then
    _log "ERROR: Virtual environment already exists."
    exit 1
fi

if [ ! -f "/opt/acc-py/apps/acc-py-cli/latest/pyvenv.cfg" ]; then
    read -p "Acc-py not found in the system. Do you want to proceed with standard Python? (Y/n): " choice
    if [[ $choice != "Y" && $choice != "y" && $choice != "" ]]; then
        exit 1
    fi
else
    ACCPY_PATH=$(grep -oP 'home = \K.*' /opt/acc-py/apps/acc-py-cli/latest/pyvenv.cfg)
    ACCPY_PATH=${ACCPY_PATH%bin}
    ACCPY_PATH+="setup.sh"
fi

# --------------------------------------------------------------------------------------------

# Migrate environment variables to the new bash session
# TODO: Does the accpy gets updated every time a session is open through pro version? How to keep the path version updated?
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

INFO_MESSAGE="Creating virtual environment ${NAME_ENV}"
if [ -d "/home/$USER/${NAME_ENV}" ]; then
    INFO_MESSAGE="Recreating (--clear) virtual environment ${NAME_ENV}"
fi

if [ -f ${ACCPY_PATH} ]; then
    INFO_MESSAGE+=" using Acc-Py..."
    source ${ACCPY_PATH}
else
    INFO_MESSAGE+=" using standard Python..."
fi

echo ${INFO_MESSAGE}

# Create the virtual environment
python -m venv /home/$USER/${NAME_ENV} --copies ${CLEAR_ENV}

# Activate the created virtual environment
echo "Activating virtual environment..."
source /home/$USER/${NAME_ENV}/bin/activate

# Install ipykernel so the kernel can be used in Jupyter
python -m pip install --upgrade -q pip
pip install ipykernel -q

# Install kernel (within the environment), so it can be ran in Jupyter 
python -m ipykernel install --name ${NAME_ENV} --display-name "Python (${NAME_ENV})" --prefix /home/$USER/${NAME_ENV}

# Create symlink from /home/$USER/${NAME_ENV}/share/jupyter/kernels/${NAME_ENV} to /home/$USER/.local/share/jupyter/kernels/${NAME_ENV}
mkdir -p /home/$USER/.local/share/jupyter/kernels
ln -s /home/$USER/${NAME_ENV}/share/jupyter/kernels/${NAME_ENV} /home/$USER/.local/share/jupyter/kernels/${NAME_ENV}

# Install the given requirements
echo "Installing packages from ${REQ_PATH}..."
pip install -q -r ${REQ_PATH}

# Copy the requirements file to the virtual environment
cp ${REQ_PATH} /home/$USER/${NAME_ENV}

echo "Virtual environment ${NAME_ENV} created successfully."
echo "WARNING: You may need to refresh the page to be able to access the new kernel in Jupyter."
 
EOF
