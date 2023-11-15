#!/bin/bash

# Author: Danilo Piparo, Enric Tejedor 2023
# Copyright CERN
# Here the environment for the notebook server is prepared. Many of the commands are launched as regular 
# user as it's this entity which is able to access eos and not the super user.

# Create notebook user
# The $HOME directory is specified upstream in the Spawner

log_info() {
    echo "[INFO $(date '+%Y-%m-%d %T.%3N') $(basename $0)] $1"
}
log_error() {
    echo "[ERROR $(date '+%Y-%m-%d %T.%3N') $(basename $0)] $1"
}

SWAN_USER="jovyan"
if [[ $HOME == /eos/* ]]; then export CERNBOX_HOME=$HOME; fi

# Remove the last slash from HOME
export HOME="${HOME%/}"

# Store the oAuth token given by the spawner inside a file
# so that EOS can use it
if [[ ! -z "$ACCESS_TOKEN" ]];
then
    log_info "Storing oAuth token for EOS"
    export OAUTH2_FILE=/tmp/eos_oauth.token
    export OAUTH2_TOKEN="FILE:$OAUTH2_FILE"
    echo -n oauth2:$ACCESS_TOKEN:$OAUTH_INSPECTION_ENDPOINT >& $OAUTH2_FILE
    log_info "oauth2:$ACCESS_TOKEN:$OAUTH_INSPECTION_ENDPOINT"
    chown -R $SWAN_USER:$NB_GID $OAUTH2_FILE
    chmod 600 $OAUTH2_FILE
fi

if [[ ! -d "$HOME" || ! -x "$HOME" ]]
then
    log_error "Error setting notebook working directory, $HOME not accessible by user $USER."
fi

export CERNBOX_OAUTH_ID="${CERNBOX_OAUTH_ID:-cernbox-service}"
export EOS_OAUTH_ID="${EOS_OAUTH_ID:-eos-service}"

# Configurations for extensions (used when deployed outside CERN)
if [[ $SHARE_CBOX_API_DOMAIN && $SHARE_CBOX_API_BASE ]]
then
  echo "{\"sharing\":
    {
      \"domain\": \"$SHARE_CBOX_API_DOMAIN\",
      \"base\": \"$SHARE_CBOX_API_BASE\",
      \"authentication\": \"/authenticate\",
      \"shared\": \"/sharing\",
      \"shared_with_me\": \"/shared\",
      \"share\": \"/share\",
      \"clone\": \"/clone\",
      \"search\": \"/search\"
  }
}" > /usr/local/etc/jupyter/nbconfig/sharing.json
fi

log_info "Finished setting up user session storage"