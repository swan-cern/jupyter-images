#!/bin/bash
# Mount EOS via WebDAV using rclone (For EOSC)

if [[ "$CERN_WEBDAV" = "true" ]]
then
  _log "Configuring WebDAV";

  # Delete the SWAN_projects folder
  rmdir "${NB_USER}/SWAN_projects"

  # Seed /tmp/swan_oauth.token for the rclone mount
  token_file=/tmp/swan_oauth.token
  echo -n "$CERNBOX_WEBDAV_TOKEN" > "$token_file"
  chown "$NB_USER:$NB_GID" "$token_file"
  chmod 600 "$token_file"
  unset CERNBOX_WEBDAV_TOKEN

  export RCLONE_CONFIG=/tmp/rclone-cernbox.conf

  uuid="${USER:0:8}-${USER:8:4}-${USER:12:4}-${USER:16:4}-${USER:20}"

  rclone config create \
    cernbox webdav \
    url https://eosc.cernbox.cern.ch/remote.php/webdav/eos/project/e/eosc/SWAN_Shared/${uuid} \
    vendor other \
    bearer_token_command "cat /tmp/swan_oauth.token"

  _log "Mounting WebDAV..";

  mkdir -p /cernbox
  ln -sfn /cernbox "/home/${NB_USER}/cernbox"
  rclone mount cernbox: /cernbox \
    --allow-other --uid "$NB_UID" --gid "$NB_GID" \
    --vfs-cache-mode full --vfs-cache-max-size 5G --cache-dir=/tmp/cache/ \
    --dir-cache-time 30s --attr-timeout 10s \
    -v --log-file=/tmp/rclone.log --daemon || cat /tmp/rclone.log
else
  _log "Skipping WebDAV configuration";
fi
