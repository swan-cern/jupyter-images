#!/bin/bash

# Author: Danilo Piparo, Enric Tejedor, Pedro Maximino, Diogo Castro 2023
# Copyright CERN
# Here the environment for the notebook server is prepared. Many of the commands are launched as regular 
# user as it's this entity which is able to access eos and not the super user.

# Set environment for the Jupyter process
LOCAL_HOME=/home/$NB_USER
export IPYTHONDIR=$LOCAL_HOME/.ipython
export JPY_DIR=$LOCAL_HOME/.jupyter
export JUPYTER_CONFIG_DIR=$JPY_DIR
export JUPYTER_PATH=$LOCAL_HOME/.local/share/jupyter

# Set other environment variables
export KERNEL_DIR=$JUPYTER_PATH/kernels
export PYTHON_KERNEL_DIR=$KERNEL_DIR/python3
export SWAN_ENV_FILE=$LOCAL_HOME/.bash_profile
export CUSTOM_JS_DIR=$JPY_DIR/custom

# Create missing directories
mkdir -p $CUSTOM_JS_DIR $IPYTHONDIR $PYTHON_KERNEL_DIR

# Move jupyter server configuration to configuration directory
mv /srv/singleuser/jupyter_swan_config.py $JUPYTER_CONFIG_DIR/jupyter_swan_config.py

# Move configuration %%cpp cell highlighting to custom directory
mv /srv/singleuser/custom.js $CUSTOM_JS_DIR/custom.js

# Move python kernel configuration to python kernel directory
mv /srv/singleuser/kernel.json $PYTHON_KERNEL_DIR/kernel.json

# Setup the LCG View on CVMFS
_log "Setting up environment from CVMFS"
export LCG_VIEW=$ROOT_LCG_VIEW_PATH/$ROOT_LCG_VIEW_NAME/$ROOT_LCG_VIEW_PLATFORM
# FIXME: Separar
# symlink $LCG_VIEW/share/jupyter/nbextensions for the notebook extensions
ln -s $LCG_VIEW/share/jupyter/nbextensions $JUPYTER_PATH
#Creating a ROOT_DATA_DIR variable
export ROOT_DATA_DIR=$(readlink $LCG_VIEW/bin/root | sed -e 's/\/bin\/root//g')

cp -L -r $LCG_VIEW/etc/jupyter/* $JUPYTER_CONFIG_DIR

# Configure kernels and terminal
# The environment of the kernels and the terminal will combine the view and the user script (if any)
_log "Configuring kernels and terminal"

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