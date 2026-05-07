#!/bin/bash
# Add Kubeflow ML token exchange for SwanOauthRenew

cat <<'EOF' >> /home/${NB_USER}/.jupyter/jupyter_server_config.py

# Renew Kubeflow token
c.SwanOauthRenew.files.append(
    ("/tmp/kubeflow_ml_oauth.token", "exchanged_tokens/kubeflow-ml", "{token}")
)
EOF
