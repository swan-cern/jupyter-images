#!/bin/bash

# Author: Rodrigo Sobral 2024
# Copyright CERN
# Here the script is used to create a virtual environment and install the packages from a provided requirements file.

_log () {
    if [ "$*" == "ERROR:"* ] || [ "$*" == "WARNING:"* ] || [ "${JUPYTER_DOCKER_STACKS_QUIET}" == "" ]; then
        echo "$@"
    fi
}

ACCPY_DEFAULT_VERSION="?"
ACCPY_ALL_VERSIONS_STR="?"
if [ -d "/opt/acc-py" ]; then
    ACCPY_ALL_VERSIONS=$(ls -tr /opt/acc-py/base)
    ACCPY_DEFAULT_VERSION=$(ls -t /opt/acc-py/base | head -n 1)
    ACCPY_ALL_VERSIONS_STR=$(echo $ACCPY_ALL_VERSIONS | tr ' ' ', ')
else 
    _log "WARNING: Acc-Py not found in the system. Using standard Python."
fi

# JDK_DEFAULT_VERSION=11

# Function to print the help page
print_help() {
    _log "Usage: makenv --env/-e NAME --req/-r REQUIREMENTS [--accpy ACCPY_VERSION] [--clear] [--no-accpy] [--help/-h]"
    _log "Options:"
    _log "  -e, --env NAME              Name of the custom virtual environment (mandatory)"
    _log "  -r, --req REQUIREMENTS      Path to requirements.txt file or http link for a public repository (mandatory)"
    _log "  -c, --clear                 Clear the current virtual environment, if it exists"
    _log "  -h, --help                  Print this help page"
    _log "  --accpy VERSION             Version of Acc-Py to be used (options: ${ACCPY_ALL_VERSIONS_STR}) (default: ${ACCPY_DEFAULT_VERSION})"
    # _log "  --jdk VERSION               Version of Java Development Kit to be used (options: 8, 11, 17, 21) (default: ${JDK_DEFAULT_VERSION})"
    _log "  --no-accpy                  Use standard Python instead of Acc-Py"
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
        # --jdk)
        #     JDK_CUSTOM_VERSION=$2
        #     if [[ $JDK_CUSTOM_VERSION != "8" && $JDK_CUSTOM_VERSION != "11" && $JDK_CUSTOM_VERSION != "17" && $JDK_CUSTOM_VERSION != "21" ]]; then
        #         _log "ERROR: Invalid JDK version. Options: 8, 11, 17, 21"
        #         exit 1
        #     fi
        #     shift
        #     shift
        #     ;;
        --accpy)
            ACCPY_CUSTOM_VERSION=$2
            # verify if the given version belongs to the available versions
            if [[ ! $ACCPY_ALL_VERSIONS[@] =~ $ACCPY_CUSTOM_VERSION ]]; then
                _log "ERROR: Invalid Acc-Py version. Options: ${ACCPY_ALL_VERSIONS_STR}"
                exit 1
            fi
            shift
            shift
            ;;
        --no-accpy)
            AVOID_ACCPY=true
            shift
            ;;
        *)
            _log "ERROR: Invalid argument: $1"
            _log
            print_help
            exit 1
            ;;
    esac
done

# --------------------------------------------------------------------------------------------

# Checks if a name for the environment is given
if [ -z "$NAME_ENV" ]; then
    _log "ERROR: No virtual environment name provided."
    _log
    print_help
    exit 1
fi

# Checks if an environment with the same name was already created, if --clear is not passed
if [ -d "/home/$USER/${NAME_ENV}" ] && [ -z "$CLEAR_ENV" ]; then
    _log "ERROR: Virtual environment already exists."
    exit 1
fi

# If ACCPY_CUSTOM_VERSION and AVOID_ACCPY are both set, trigger an error
if [ -n "$ACCPY_CUSTOM_VERSION" ] && [ -n "$AVOID_ACCPY" ]; then
    _log "ERROR: --no-accpy and --accpy are both set. Please choose only one of the options."
    exit 1
fi

# Checks if a requirements file is given
if [ -z "$requirements" ]; then
    _log "ERROR: No requirements provided."
    _log
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

    # Set the requirements path to the cloned repository
    REQ_PATH=$PWD/$repo_name/requirements.txt
else
    _log "ERROR: Requirements not found."
    exit 1
fi

# Verify if the requirements file is not empty
if [ ! -s ${REQ_PATH} ]; then
    echo "ERROR: Requirements file is empty."
    exit 1
fi

ACCPY_PATH=""
if [ -z "$AVOID_ACCPY" ]; then
    ACCPY_VERSION=$ACCPY_DEFAULT_VERSION
    if [ -n "$ACCPY_CUSTOM_VERSION" ]; then
        ACCPY_VERSION=$ACCPY_CUSTOM_VERSION
    fi
    ACCPY_PATH="/opt/acc-py/base/${ACCPY_VERSION}/setup.sh"
    # if [ ! -f "$ACCPY_PATH" ]; then
    #     read -p "Acc-py (${ACCPY_VERSION}) not found in the system. Do you want to proceed with standard Python? (Y/n): " choice
    #     if [[ $choice != "Y" && $choice != "y" && $choice != "" ]]; then
    #         exit 1
    #     fi
    # fi
fi

# JDK_VERSION=$JDK_DEFAULT_VERSION
# if [ -n "$JDK_CUSTOM_VERSION" ]; then
#     JDK_VERSION=$JDK_CUSTOM_VERSION
# fi

INFO_MESSAGE="Creating virtual environment ${NAME_ENV}"
if [ -d "/home/$USER/${NAME_ENV}" ]; then
    INFO_MESSAGE="Recreating (--clear) virtual environment ${NAME_ENV}"
fi
if [ -n "$ACCPY_PATH" ] && [ -f $ACCPY_PATH ]; then
    INFO_MESSAGE+=" using Acc-Py (${ACCPY_VERSION})..."
else
    INFO_MESSAGE+=" using standard Python..."
fi

# --------------------------------------------------------------------------------------------


# Migrate environment variables to the new bash session
PATH=$PATH
USER=$USER
OAUTH2_FILE=$OAUTH2_FILE
OAUTH2_TOKEN=$OAUTH2_TOKEN
KRB5CCNAME=$KRB5CCNAME
KRB5CCNAME_NB_TERM=$KRB5CCNAME_NB_TERM
JUPYTER_DOCKER_STACKS_QUIET=$JUPYTER_DOCKER_STACKS_QUIET
# JAVA_HOME="/var/lib/alternatives/java_${JDK_VERSION}_openjdk"

# Create a new bash session to avoid conflicts with the current environment in the background
env -i bash --noprofile --norc << EOF

export ACCPY_PATH=${ACCPY_PATH}
export PATH=${PATH}
export USER=${USER}
export OAUTH2_FILE=${OAUTH2_FILE}
export OAUTH2_TOKEN=${OAUTH2_TOKEN}
export KRB5CCNAME=${KRB5CCNAME}
export KRB5CCNAME_NB_TERM=${KRB5CCNAME_NB_TERM}
# export JAVA_HOME=${JAVA_HOME}

echo "${INFO_MESSAGE}"

if [ -n "$ACCPY_PATH" ] && [ -f $ACCPY_PATH ]; then
    source $ACCPY_PATH
fi

# Create the virtual environment
python -m venv /home/$USER/${NAME_ENV} ${CLEAR_ENV}

# Activate the created virtual environment
echo "Preparing virtual environment..."
source /home/$USER/${NAME_ENV}/bin/activate

# Install ipykernel so the kernel can be used in Jupyter
python -m pip install --upgrade -q pip
pip install ipykernel -q

# Install kernel (within the environment), so it can be ran in Jupyter 
python -m ipykernel install --name ${NAME_ENV} --display-name "Python (${NAME_ENV})" --prefix /home/$USER/.local 2> /dev/null

# Install the given requirements
echo "Installing packages from ${REQ_PATH}..."
pip install -q -r ${REQ_PATH}

# Copy the requirements file to the virtual environment
cp ${REQ_PATH} /home/$USER/${NAME_ENV}

echo "Virtual environment ${NAME_ENV} created successfully."
echo "WARNING: You may need to refresh the page to be able to access the new kernel in Jupyter."
 
EOF
