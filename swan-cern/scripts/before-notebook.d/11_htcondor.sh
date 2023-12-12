#!/bin/bash

# Author: Danilo Piparo, Enric Tejedor, Pedro Maximino, Diogo Castro 2023
# Copyright CERN
# The HT Condor environment is configured here. It creates the certificates
# and sets additional configuration to access a dask cluster.

# HTCondor at CERN integration
if [[ $CERN_HTCONDOR ]]
then
  _log "Configuring HTCondor";
  
  export CONDOR_CONFIG=/eos/project/l/lxbatch/public/config-condor-swan/condor_config
  mkdir -p /etc/condor/config.d/ /etc/myschedd/
  ln -s /eos/project/l/lxbatch/public/config-condor-swan/config.d/10_cernsubmit.erb /etc/condor/config.d/10_cernsubmit.erb
  ln -s /eos/project/l/lxbatch/public/config-condor-swan/myschedd.yaml /etc/myschedd/myschedd.yaml
  ln -s /eos/project/l/lxbatch/public/config-condor-swan/ngbauth-submit /etc/sysconfig/ngbauth-submit

  # Create self-signed certificate for Dask processes
  export DASK_TLS_DIR=/srv/dask/tls # export so SwanHTCondorCluster finds the certs
  mkdir -p $DASK_TLS_DIR
  chown -R $NB_USER:$NB_GID $DASK_TLS_DIR
  _log "Generating certificate for Dask"
  sudo -u $NB_USER sh /srv/singleuser/create_dask_certs.sh $DASK_TLS_DIR &

  # Ensure Dask clients call us to create a default Security object
  export DASK_DISTRIBUTED__CLIENT__SECURITY_LOADER="swandaskcluster.security.loader"
else
   _log "Skipping HTCondor configuration";
fi