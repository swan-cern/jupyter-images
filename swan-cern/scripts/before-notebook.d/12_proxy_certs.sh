#!/bin/bash

# Author: Ben Jones, Enric Tejedor, Pedro Maximino 2024
# Copyright CERN
# Adds support for the generation of VOMS proxy certificates.

if [[ -d /cvmfs/grid.cern.ch ]]
then
    ln -s /cvmfs/grid.cern.ch/etc/grid-security /etc/grid-security
    ln -s /cvmfs/grid.cern.ch/etc/grid-security/vomses /etc/vomses
    # The link below should point to an alma9 voms-proxy-init when that is available
    ln -s /cvmfs/grid.cern.ch/centos7-umd4-ui-4.0.3-1_191004/usr/bin/voms-proxy-init /usr/bin/voms-proxy-init    
fi