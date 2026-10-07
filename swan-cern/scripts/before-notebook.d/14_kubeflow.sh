#!/bin/bash
# Add Kubeflow ML token exchange for SwanOauthRenew

if [[ "$CERN_KUBEFLOW" = "true" ]]
then
  _log "Configuring Kubeflow";

  cat <<'EOF' >> /home/${NB_USER}/.jupyter/jupyter_server_config.py

# Renew Kubeflow token
c.SwanOauthRenew.files.append(
    ("/tmp/kubeflow_ml_oauth.token", "exchanged_tokens/kubeflow-ml", "{token}")
)
EOF

else
  _log "Skipping Kubeflow configuration";
  # Disable Kubeflow lab extension
  config_file="/etc/jupyter/labconfig/page_config.json"

  if [[ ! -e "$config_file" ]]
  then
      mkdir -p "$(dirname $config_file)"
      jq -n --argjson swan-ml true \
        '{disabledExtensions: $ARGS.named}' > $config_file
  else
      jq '.disabledExtensions["swan-ml"]=true' $config_file > "/tmp/page_config.json"
      mv "/tmp/page_config.json" $config_file
  fi
fi
