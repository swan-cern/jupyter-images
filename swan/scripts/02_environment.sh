#!/bin/sh

# Author: Danilo Piparo, Enric Tejedor 2023
# Copyright CERN
# Here the environment for the notebook server is prepared. Many of the commands are launched as regular 
# user as it's this entity which is able to access eos and not the super user.

export USER="jovyan"
export NB_USER=$USER
SWAN_HOME="/home/jovyan"

log_info() {
    echo "[INFO $(date '+%Y-%m-%d %T.%3N') $(basename $0)] $1"
}
log_error() {
    echo "[ERROR $(date '+%Y-%m-%d %T.%3N') $(basename $0)] $1"
}

# Set environment for the Jupyter process
export IPYTHONDIR=/home/$USER/.ipython
export JPY_DIR=/home/$USER/.jupyter
export JUPYTER_CONFIG_DIR=$JPY_DIR
export JUPYTER_PATH=/home/$USER/.local/share/jupyter

# Set other environment variables
export KERNEL_DIR=$JUPYTER_PATH/kernels
export SWAN_ENV_FILE=$SWAN_HOME/.bash_profile

export CUSTOM_JS_DIR=$JPY_DIR/custom

# Create missing directories
mkdir -p ${CUSTOM_JS_DIR} ${IPYTHONDIR} ${KERNEL_DIR} && \
chown -R ${USER}:${NB_GID} ${IPYTHONDIR}

# Disable pinging for maintenance notifications when running on Kubernetes
if [ "${SWAN_DISABLE_NOTIFICATIONS}" == "true" ]; 
then
  log_info "Disable SwanNotifications extension"
  jupyter nbextension disable swannotifications/extension --system --section common
fi

# This avoids to create hardlinks on eos when using pip
export XDG_CACHE_HOME=/tmp/$NB_USER/.cache/

# Setup the LCG View on CVMFS
log_info "Setting up environment from CVMFS"
export LCG_VIEW=$ROOT_LCG_VIEW_PATH/$ROOT_LCG_VIEW_NAME/$ROOT_LCG_VIEW_PLATFORM
# FIXME: Separar
# symlink $LCG_VIEW/share/jupyter/nbextensions for the notebook extensions
ln -s $LCG_VIEW/share/jupyter/nbextensions $JUPYTER_PATH
#Creating a ROOT_DATA_DIR variable
export ROOT_DATA_DIR=$(readlink $LCG_VIEW/bin/root | sed -e 's/\/bin\/root//g')

cp -L -r $LCG_VIEW/etc/jupyter/* $JUPYTER_CONFIG_DIR

# Configure kernels and terminal
# The environment of the kernels and the terminal will combine the view and the user script (if any)
log_info "Configuring kernels and terminal"

# FIXME: Move to kernel.json file
PYKERNELDIR=$KERNEL_DIR/python3
mkdir -p $PYKERNELDIR
echo "{
 \"display_name\": \"Python 3\",
 \"language\": \"python\",
 \"argv\": [
  \"python\",
  \"/usr/local/bin/start_ipykernel.py\",
  \"-f\",
  \"{connection_file}\"
 ]
}" > $PYKERNELDIR/kernel.json

# ROOT
cp -rL $LCG_VIEW/etc/notebook/kernels/root $KERNEL_DIR

# R
cp -rL $LCG_VIEW/share/jupyter/kernels/ir $KERNEL_DIR
sed -i "s/IRkernel::main()/options(bitmapType='cairo');IRkernel::main()/g" $KERNEL_DIR/ir/kernel.json # Force cairo for graphics

# Octave
OCTAVE_KERNEL_PATH=$LCG_VIEW/share/jupyter/kernels/octave
if [[ -d $OCTAVE_KERNEL_PATH ]];
then
   cp -rL $OCTAVE_KERNEL_PATH $KERNEL_DIR
   export OCTAVE_KERNEL_JSON=$KERNEL_DIR/octave/kernel.json
fi

# Julia
JULIA_KERNEL_PATH=$LCG_VIEW/share/jupyter/kernels/julia-*
if [ -d $JULIA_KERNEL_PATH ];
then
  cp -rL $JULIA_KERNEL_PATH $KERNEL_DIR
fi

bash /usr/local/bin/start-notebook.d/03_userconfig.sh

if [ $? -ne 0 ]
then
  log_error "Error configuring user environment"
  exit 1
fi

START_TIME_CONFIGURE_KERNEL_ENV=$( date +%s.%N )

if [[ $HELP_ENDPOINT ]]
then
  echo "{
    \"help\": \"$HELP_ENDPOINT\"
}" > /usr/local/etc/jupyter/nbconfig/help.json
fi

export SWAN_ENV_FILE=$SWAN_HOME/.bash_profile

# Make sure we have a sane terminal
printf "export TERM=xterm\n" >> $SWAN_ENV_FILE

# If there, source users' .bashrc after the SWAN environment
BASHRC_LOCATION=$SWAN_HOME/.bashrc
printf "if [[ -f $BASHRC_LOCATION ]];
then
   source $BASHRC_LOCATION
fi\n" >> $SWAN_ENV_FILE

if [ $? -ne 0 ]
then
  log_error "Error setting the environment for kernels"
  exit 1
else
  CONFIGURE_KERNEL_ENV_TIME_SEC=$(echo $(date +%s.%N --date="$START_TIME_CONFIGURE_KERNEL_ENV seconds ago") | bc)
  log_info "user: $USER, host: ${SERVER_HOSTNAME%%.*}, metric: configure_kernel_env.${ROOT_LCG_VIEW_NAME:-none}.${SPARK_CLUSTER_NAME:-none}.duration_sec, value: $CONFIGURE_KERNEL_ENV_TIME_SEC"
fi

# Allow further configuration by sysadmin (usefull outside of CERN)
if [[ $CONFIG_SCRIPT ]]; 
then
  log_info "Found user config script"
  sh $CONFIG_SCRIPT
fi

log_info "Finished setting up CVMFS and user environment"