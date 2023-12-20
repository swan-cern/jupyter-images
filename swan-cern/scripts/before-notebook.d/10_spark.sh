#!/bin/bash

# Author: Danilo Piparo, Enric Tejedor, Pedro Maximino, Diogo Castro 2023
# Copyright CERN
# The environment for Spark is configured here. It allows CERN users to
# connect to spark clusters and use their computational resources
# through SWAN.

if [[ -n $SPARK_CLUSTER_NAME ]]
then
   _log "Configuring Spark";

  # Jupyter server configuration path
  JPY_CONFIG=$JUPYTER_CONFIG_DIR/jupyter_server_config.py
  LOCAL_IP=`hostname -i`
  echo "$LOCAL_IP $SERVER_HOSTNAME" >> /etc/hosts

  # Enable the extensions in Jupyter global path to avoid having to maintain this information 
  # in the user scratch json file (specially because now we persist this file in the user directory and
  # we don't want to persist the Spark extensions across sessions)
  mkdir -p /etc/jupyter/nbconfig
  _log "Globally enabling the Spark extensions"
  jq -n --argjson sparkconnector/extension true \
        '{load_extensions: $ARGS.named}' > /etc/jupyter/nbconfig/notebook.json

  sed -i "1s/^/c.InteractiveShellApp.extensions.append('sparkconnector.connector')\n/" \
      /home/$NB_USER/.ipython/profile_default/ipython_kernel_config.py
else
  # Disable spark jupyterlab extensions enabled by default if no cluster is selected
  mkdir -p /etc/jupyter/labconfig
  jq -n --argjson @swan-cern/sparkconnector true \
        --argjson jupyterlab_sparkmonitor true \
        '{disabledExtensions: $ARGS.named}' > /etc/jupyter/labconfig/page_config.json
  _log "Skipping Spark configuration";
fi