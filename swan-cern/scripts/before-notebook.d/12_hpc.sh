if [[ -n $HPC_ENABLED ]]
then
   _log "Configuring HPC";

    # Update the HPC oAuth token automatically
    echo "c.SwanOauthRenew.files.append(('/tmp/slurm_oauth.token', 'exchanged_tokens/slurm', '{token}'))" >> /home/${NB_USER}/.jupyter/jupyter_server_config.py
fi