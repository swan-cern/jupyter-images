#!/bin/bash

# Author: Danilo Piparo, Enric Tejedor, Pedro Maximino, Diogo Castro 2023
# Copyright CERN
# The environment for Spark is configured here.

if [[ -n $SPARK_CLUSTER_NAME ]]
then
  # Jupyter server configuration path
  JPY_CONFIG=$JUPYTER_CONFIG_DIR/jupyter_server_config.py
  LOCAL_IP=`hostname -i`
  echo "$LOCAL_IP $SERVER_HOSTNAME" >> /etc/hosts

  # Enable the extensions in Jupyter global path to avoid having to maintain this information 
  # in the user scratch json file (specially because now we persist this file in the user directory and
  # we don't want to persist the Spark extensions across sessions)
  mkdir -p /etc/jupyter/nbconfig
  _log "Globally enabling the Spark extensions"
  echo "{
    \"load_extensions\": {
      \"sparkconnector/extension\": true,
      \"hdfsbrowser/extension\": true
    }
  }" > /etc/jupyter/nbconfig/notebook.json
  echo "{
    \"NotebookApp\": {
      \"jpserver_extensions\": {
        \"hdfsbrowser.serverextension\": true
      }
    }
  }" > /etc/jupyter/jupyter_notebook_config.json
  if [ $SPARK_CLUSTER_NAME = "k8s" ]
  then
    NAMESPACE="analytix"
    CLUSTER_NAME="analytix"
  else
    NAMESPACE=$(cat /cvmfs/sft.cern.ch/lcg/etc/hadoop-confext/conf/etc/$SPARK_CLUSTER_NAME/$SPARK_CLUSTER_NAME.info.json | python -c 'import json,sys;obj=json.load(sys.stdin);print(obj["namespace"])')
    CLUSTER_NAME=$SPARK_CLUSTER_NAME
  fi

  echo 'c.HDFSBrowserConfig.hdfs_site_path = "/cvmfs/sft.cern.ch/lcg/etc/hadoop-confext/conf/etc/'"$CLUSTER_NAME"'/hadoop.'"$CLUSTER_NAME"'/hdfs-site.xml"
  c.HDFSBrowserConfig.hdfs_site_namenodes_property = "dfs.ha.namenodes.'"$NAMESPACE"'"
  c.HDFSBrowserConfig.hdfs_site_namenodes_port = "50070"' >> $JPY_CONFIG
else
  # Disable spark jupyterlab extensions enabled by default if no cluster is selected
  mkdir -p /etc/jupyter/labconfig
  echo "{
    \"disabledExtensions\": {
      \"sparkconnector\": true,
      \"@swan-cern/hdfsbrowser\": true,
      \"jupyterlab_sparkmonitor\": true
    }
  }" > /etc/jupyter/labconfig/page_config.json
fi