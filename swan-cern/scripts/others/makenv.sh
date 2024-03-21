#!/bin/bash

# Author: Rodrigo Sobral 2024
# Copyright CERN
# Here the script is used to create a virtual environment and install the packages from a provided requirements file.

_log () {
    if [ "$*" == "ERROR:"* ] || [ "$*" == "WARNING:"* ] || [ "${JUPYTER_DOCKER_STACKS_QUIET}" == "" ]; then
        echo "$@"
    fi
}

ACCPY_ALL_VERSIONS_STR="?"
PYTHON_DEFAULT_PATH=$(which python)
if [ -d "/opt/acc-py" ]; then
    ACCPY_ALL_VERSIONS=$(ls -tr /opt/acc-py/base)
    ACCPY_ALL_VERSIONS_STR=$(echo $ACCPY_ALL_VERSIONS | tr ' ' ', ')
fi


# Function to print the help page
print_help() {
    _log "Usage: makenv --env/-e NAME --req/-r REQUIREMENTS [--accpy ACCPY_VERSION] [--python PATH] [--clear/-c] [--help/-h]"
    _log "Options:"
    _log "  -e, --env NAME              Name of the custom virtual environment (mandatory)"
    _log "  -r, --req REQUIREMENTS      Path to requirements.txt file or http link for a public repository (mandatory)"
    _log "  -c, --clear                 Clear the current virtual environment, if it exists"
    _log "  -h, --help                  Print this help page"
    _log "  --accpy VERSION             Version of Acc-Py to be used (options: ${ACCPY_ALL_VERSIONS_STR})"
    _log "  --python PATH               Path to the Python interpreter to be used (default: ${PYTHON_DEFAULT_PATH})"
}

# --------------------------------------------------------------------------------------------

# Parse command line arguments
while [ $# -gt 0 ]; do
    key="$1"
    case $key in
        --env|-e)
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
        --accpy)
            ACCPY_CUSTOM_VERSION=$2
            shift
            shift
            ;;
        --python)
            PYTHON_CUSTOM_PATH=$2
            shift
            shift
            ;;
        *)
            _log "ERROR: Invalid argument: $1" && _log
            print_help
            exit 1
            ;;
    esac
done

# --------------------------------------------------------------------------------------------

ENV_PATH="/home/$USER/${NAME_ENV}"
PYTHON_PATH=$PYTHON_DEFAULT_PATH
if [ -n "$PYTHON_CUSTOM_PATH" ]; then
    PYTHON_PATH=$PYTHON_CUSTOM_PATH
fi

# Checks if a name for the environment is given
if [ -z "$NAME_ENV" ]; then
    _log "ERROR: No virtual environment name provided." && _log
    print_help
    exit 1
fi

# Checks if an environment with the same name was already created, if --clear is not passed
if [ -d "$ENV_PATH" ] && [ -z "$CLEAR_ENV" ]; then
    _log "ERROR: Virtual environment already exists."
    exit 1
fi

# Checks if AccPy and Python are both set, trigger an error
if [ -n "$ACCPY_CUSTOM_VERSION" ] && [ -n "$PYTHON_CUSTOM_PATH" ]; then
    _log "ERROR: --python and --accpy are both set. Please choose only one of the options."
    exit 1
fi

# Checks if the provided Python interpreter is found
if [ ! -f $PYTHON_CUSTOM_PATH ]; then
    _log "ERROR: Python interpreter not found."
    exit 1
fi

# Checks if the provided Acc-Py version is valid
if [[ ! $ACCPY_ALL_VERSIONS[@] =~ $ACCPY_CUSTOM_VERSION ]]; then
    _log "ERROR: Invalid Acc-Py version. Options: ${ACCPY_ALL_VERSIONS_STR}"
    exit 1
fi

# Checks if a requirements file is given
if [ -z "$requirements" ]; then
    _log "ERROR: No requirements provided." && _log
    print_help
    exit 1
# Checks if the provided requirements source is found
elif [ -f $requirements ]; then
    if [[ ${requirements##*.} != "txt" ]]; then
        _log "ERROR: Invalid requirements file."
        exit 1
    fi
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
    git clone $requirements -q --template /usr/share/git-core/templates || { _log "ERROR: Failed to clone repository"; exit 1; }

    # Check if requirements.txt exists in the repository
    if [ ! -f $repo_name/requirements.txt ]; then
        rm -rf $repo_name
        _log "ERROR: requirements.txt not found in the repository"
        exit 1
    fi

    REQ_PATH=$PWD/$repo_name/requirements.txt
else
    _log "ERROR: Requirements not found."
    exit 1
fi

# Checks if the requirements file is not empty
if [ ! -s "$REQ_PATH" ]; then
    echo "ERROR: Requirements file is empty."
    exit 1
fi



# --------------------------------------------------------------------------------------------


# Credentials for the bash process to have access to EOS
OAUTH2_FILE=$OAUTH2_FILE
OAUTH2_TOKEN=$OAUTH2_TOKEN
KRB5CCNAME=$KRB5CCNAME
KRB5CCNAME_NB_TERM=$KRB5CCNAME_NB_TERM

# Create a new bash session to avoid conflicts with the current environment in the background, in case the user chooses Acc-Py
env -i bash --noprofile --norc << EOF

export OAUTH2_FILE=${OAUTH2_FILE}
export OAUTH2_TOKEN=${OAUTH2_TOKEN}
export KRB5CCNAME=${KRB5CCNAME}
export KRB5CCNAME_NB_TERM=${KRB5CCNAME_NB_TERM}

if [ -n "$ACCPY_CUSTOM_VERSION" ]; then
    source /opt/acc-py/base/${ACCPY_CUSTOM_VERSION}/setup.sh
    if [ -d "${ENV_PATH}" ] && [ -n "${CLEAR_ENV}" ]; then
        rm -rf ${ENV_PATH}
    fi
    acc-py venv ${ENV_PATH}
else
    if [ -d "${ENV_PATH}" ]; then
        echo "Recreating (--clear) virtual environment ${NAME_ENV} using Python (${PYTHON_PATH})..."
    else
        echo "Creating virtual environment ${NAME_ENV} using Python (${PYTHON_PATH})..."
    fi
    ${PYTHON_PATH} -m venv ${ENV_PATH} ${CLEAR_ENV} --copies
fi

mkdir -p /home/$USER/.local/share/jupyter/kernels
ln -f -s ${ENV_PATH}/share/jupyter/kernels/${NAME_ENV} /home/$USER/.local/share/jupyter/kernels/${NAME_ENV}

echo "Setting up the virtual environment..."
source ${ENV_PATH}/bin/activate

# Check if ACCPY_CUSTOM_VERSION is not set and ipykernel is on the requirements file, if not, add the latest version
if [ -z "$ACCPY_CUSTOM_VERSION" ] && [ -z "$(grep -i 'ipykernel' ${REQ_PATH})" ]; then
    echo "ipykernel" >> ${REQ_PATH}
fi

echo "Installing packages from ${REQ_PATH}..."
pip install -r ${REQ_PATH}

python -m ipykernel install --name ${NAME_ENV} --display-name "Python (${NAME_ENV})" --prefix ${ENV_PATH}

# Remove ipykernel package from the requirements file, if it was added
if [ -z "$ACCPY_CUSTOM_VERSION" ] && [ -z "$(grep -i 'ipykernel' ${REQ_PATH})" ]; then
    sed -i '/ipykernel/d' ${REQ_PATH}
fi

# Copy the requirements file to the virtual environment
cp ${REQ_PATH} ${ENV_PATH}

echo "Virtual environment ${NAME_ENV} created successfully."
echo "WARNING: You may need to refresh the page to be able to access the new kernel in Jupyter."
EOF