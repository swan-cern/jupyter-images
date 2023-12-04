#!/bin/bash

# Author: Danilo Piparo, Enric Tejedor, Pedro Maximino, Diogo Castro 2023
# Copyright CERN
# Here the environment for the notebook server is prepared. Many of the commands are 
# launched as regular user as it's this entity which is able to access 
# eos and not the super user.

# Set environment for the Jupyter process
LOCAL_HOME=/home/$NB_USER
export IPYTHONDIR=$LOCAL_HOME/.ipython
export JPY_DIR=$LOCAL_HOME/.jupyter

# JUPYTER_CONFIG_DIR is set to point to the local user home (/home/$USER)
# instead of the EOS path
export JUPYTER_CONFIG_DIR=$JPY_DIR
export JUPYTER_PATH=$LOCAL_HOME/.local/share/jupyter

# Set other environment variables
export KERNEL_DIR=$JUPYTER_PATH/kernels
export SWAN_ENV_FILE=$LOCAL_HOME/.bash_profile
export PROFILEPATH=$IPYTHONDIR/profile_default

# Create missing directories
mkdir -p $IPYTHONDIR $PROFILEPATH

# Setup the LCG View on CVMFS
_log "Setting up environment from CVMFS"
export LCG_VIEW=$ROOT_LCG_VIEW_PATH/$ROOT_LCG_VIEW_NAME/$ROOT_LCG_VIEW_PLATFORM

# symlink $LCG_VIEW/share/jupyter/nbextensions for the notebook extensions
ln -s $LCG_VIEW/share/jupyter/nbextensions $JUPYTER_PATH

cp -L -r $LCG_VIEW/etc/jupyter/* $JUPYTER_CONFIG_DIR

# Configure kernels and terminal
# The environment of the kernels and the terminal will combine the view and the user script (if any)
_log "Configuring kernels and terminal"

# ROOT
ROOT_KERNEL_PATH=$LCG_VIEW/etc/notebook/kernels/root
if [ -d $ROOT_KERNEL_PATH ];
then
  cp -rL $ROOT_KERNEL_PATH $KERNEL_DIR
fi

# R
R_KERNEL_PATH=$LCG_VIEW/share/jupyter/kernels/ir
if [ -d $R_KERNEL_PATH ];
then
  cp -rL $R_KERNEL_PATH $KERNEL_DIR
  sed -i "s/IRkernel::main()/options(bitmapType='cairo');IRkernel::main()/g" $KERNEL_DIR/ir/kernel.json # Force cairo for graphics
fi

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

# Grant privileges to all files inside the created directories and subdirectoies
# to the user
chown -R $NB_USER:$NB_GID $LOCAL_HOME

_log "Running user configuration script for user $NB_USER."
sudo -E -u $NB_USER bash /srv/singleuser/scripts/userconfig.sh

if [ $? -ne 0 ]
then
  _log "Error configuring user environment"
  exit 1
fi

START_TIME_CONFIGURE_KERNEL_ENV=$( date +%s.%N )

# Make sure we have a sane terminal
printf "export TERM=xterm\n" >> $SWAN_ENV_FILE

# If there, source users' .bashrc after the SWAN environment
BASHRC_LOCATION=$HOME/.bashrc
printf "if [[ -f $BASHRC_LOCATION ]];
then
  source $BASHRC_LOCATION
fi\n" >> $SWAN_ENV_FILE

if [ $? -ne 0 ]
then
  _log "Error setting the environment for kernels"
  exit 1
else
  CONFIGURE_KERNEL_ENV_TIME_SEC=$(echo $(date +%s.%N --date="$START_TIME_CONFIGURE_KERNEL_ENV seconds ago") | bc)
  _log "user: $NB_USER, host: ${SERVER_HOSTNAME%%.*}, metric: configure_kernel_env.${ROOT_LCG_VIEW_NAME:-none}.${SPARK_CLUSTER_NAME:-none}.duration_sec, value: $CONFIGURE_KERNEL_ENV_TIME_SEC"
fi

# Set the terminal environment
#in jupyter 6.0.0 login shell (jupyter/notebook#4112) is set by default and /etc/profile.d is respected
echo "source $LOCAL_HOME/.bash_profile" > /etc/profile.d/swan.sh

_log "Finished setting up CVMFS and user environment"