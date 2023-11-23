#!/bin/bash

# Author: Danilo Piparo, Enric Tejedor, Pedro Maximino, Diogo Castro 2023
# Copyright CERN
# Here the storage environment is prepared, to ensure the user is able to access
# their home directory (EOS for CERN users).

# The $HOME directory is specified upstream in the Spawner
if [[ $HOME == /eos/* ]]; then export CERNBOX_HOME=$HOME; fi

# Remove the last slash from HOME
export HOME="${HOME%/}"

# Store the oAuth token given by the spawner inside a file
# so that EOS can use it
if [[ ! -z "$ACCESS_TOKEN" ]];
then
    _log "Storing oAuth token for EOS"
    export OAUTH2_FILE=/tmp/eos_oauth.token
    export OAUTH2_TOKEN="FILE:$OAUTH2_FILE"
    echo -n oauth2:$ACCESS_TOKEN:$OAUTH_INSPECTION_ENDPOINT >& $OAUTH2_FILE
    chown -R $NB_USER:$NB_GID $OAUTH2_FILE
    chmod 600 $OAUTH2_FILE
fi

if [[ ! -d "$HOME" || ! -x "$HOME" ]]
then
    _log "Error setting notebook working directory, $HOME not accessible by user $NB_USER."
    exit 1
fi

export CERNBOX_OAUTH_ID="${CERNBOX_OAUTH_ID:-cernbox-service}"
export EOS_OAUTH_ID="${EOS_OAUTH_ID:-eos-service}"

# Configurations for extensions (used when deployed outside CERN)
if [[ $SHARE_CBOX_API_DOMAIN && $SHARE_CBOX_API_BASE ]]
then
    _log "Updated the user home to $HOME."
fi

_log "Finished setting up user session storage"