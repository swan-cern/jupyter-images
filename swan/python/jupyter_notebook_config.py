import os
from swancontents import get_templates

c.FileCheckpoints.checkpoint_dir = os.environ.get("HOME") + "/.ipynb_checkpoints"
c.NotebookNotary.db_file = os.environ.get("JUPYTER_PATH") + "/nbsignatures.db"
c.NotebookNotary.secret_file = os.environ.get("JUPYTER_PATH") + "/notebook_secret"
c.ContentsManager.checkpoints_class = "swancontents.filemanager.checkpoints.EOSCheckpoints"

c.NotebookApp.contents_manager_class = "swancontents.filemanager.swanfilemanager.SwanFileManager"
c.NotebookApp.default_url = "lab" if os.environ.get("SWAN_USE_JUPYTERLAB") == "true" else "projects"

root_data_dir = os.environ.get("ROOT_DATA_DIR")
if root_data_dir is not None:
  c.NotebookApp.extra_static_paths = [root_data_dir + "/js"]
# Fixes issue with frozen servers with async io errors, fix from https://github.com/jupyter/notebook/issues/6164
c.NotebookApp.kernel_manager_class = "notebook.services.kernels.kernelmanager.AsyncMappingKernelManager"

# Convert the _xsrf cookie into a session cookie, to prevent it from having an expiration date of 30 days
# Without this setting, _xsrf cookie could expire in the middle of a user editing a notebook, making it
# impossible to save the notebook without refreshing the page and losing unsaved changes.
c.NotebookApp.tornado_settings = {
  "xsrf_cookie_kwargs": {
    "expires_days": None,
    "expires": None
  }
}

gallery_url = os.environ.get("GALLERY_URL")
if gallery_url is not None:
  c.NotebookApp.jinja_template_vars = {
      "gallery_url": gallery_url
  }

c.NotebookApp.extra_template_paths = [get_templates()]

cernbox_oauth_id = os.environ.get("CERNBOX_OAUTH_ID", "cernbox-service")
eos_oauth_id = os.environ.get("EOS_OAUTH_ID", "eos-service")
oauth2_file = os.environ.get("OAUTH2_FILE", "")
oauth_inspection_endpoint = os.environ.get("OAUTH_INSPECTION_ENDPOINT", "")
c.SwanOauthRenew.files = [
    ("/tmp/swan_oauth.token", "access_token", "{token}"),
    ("/tmp/cernbox_oauth.token", f"exchanged_tokens/{cernbox_oauth_id}", "{token}"),
    (oauth2_file, f"exchanged_tokens/{eos_oauth_id}", "oauth2:{token}:" + oauth_inspection_endpoint)
]

share_cbox_api_domain = os.environ.get("SHARE_CBOX_API_DOMAIN")
if share_cbox_api_domain is not None:
  c.SwanShare.cernbox_url = share_cbox_api_domain