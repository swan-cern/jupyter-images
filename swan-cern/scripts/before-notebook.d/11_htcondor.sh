#!/bin/bash

# Author: Danilo Piparo, Enric Tejedor, Pedro Maximino, Diogo Castro 2023
# Copyright CERN
# The HT Condor environment is configured here.

# HTCondor at CERN integration
if [[ $CERN_HTCONDOR ]]
then
  export CONDOR_CONFIG=/eos/project/l/lxbatch/public/config-condor-swan/condor_config
  mkdir -p /etc/condor/config.d/ /etc/myschedd/
  ln -s /eos/project/l/lxbatch/public/config-condor-swan/config.d/10_cernsubmit.erb /etc/condor/config.d/10_cernsubmit.erb
  ln -s /eos/project/l/lxbatch/public/config-condor-swan/myschedd.yaml /etc/myschedd/myschedd.yaml
  ln -s /eos/project/l/lxbatch/public/config-condor-swan/ngbauth-submit /etc/sysconfig/ngbauth-submit

  # Create self-signed certificate for Dask processes
  _log "Generating certificate for Dask"
  chown -R $NB_USER:$NB_GID $DASK_TLS_DIR
  sudo -u $NB_USER sh /srv/singleuser/create_dask_certs.sh $DASK_TLS_DIR &

  # Dask config: lab extension must use SwanHTCondorCluster
  DASK_CONFIG_DIR=/etc/dask 
  mkdir $DASK_CONFIG_DIR
  echo "
labextension:
  factory:
    module: 'swandaskcluster'
    class: 'SwanHTCondorCluster'
    args: []
    kwargs: {}  
  " > $DASK_CONFIG_DIR/labextension.yaml
else
   _log "Skipping HTCondor configuration";
fi