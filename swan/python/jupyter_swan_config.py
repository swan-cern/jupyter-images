import os
from swancontents import get_templates

c.FileCheckpoints.checkpoint_dir = os.environ.get("HOME") + "/.ipynb_checkpoints"
c.NotebookNotary.db_file = os.environ.get("JUPYTER_PATH") + "/nbsignatures.db"
c.NotebookNotary.secret_file = os.environ.get("JUPYTER_PATH") + "/notebook_secret"

# TODO: Needs to change
c.NotebookApp.contents_manager_class = "swancontents.filemanager.swanfilemanager.SwanFileManager"

root_data_dir = os.environ.get("ROOT_DATA_DIR")
if root_data_dir is not None:
  c.NotebookApp.extra_static_paths = [root_data_dir + "/js"]

# Convert the _xsrf cookie into a session cookie, to prevent it from having an expiration date of 30 days
# Without this setting, _xsrf cookie could expire in the middle of a user editing a notebook, making it
# impossible to save the notebook without refreshing the page and losing unsaved changes.
# c.NotebookApp.tornado_settings = {
#   "xsrf_cookie_kwargs": {
#     "expires_days": None,
#     "expires": None
#   }
# }

cernbox_oauth_id = os.environ.get("CERNBOX_OAUTH_ID", "cernbox-service")
eos_oauth_id = os.environ.get("EOS_OAUTH_ID", "eos-service")
oauth2_file = os.environ.get("OAUTH2_FILE", "")
oauth_inspection_endpoint = os.environ.get("OAUTH_INSPECTION_ENDPOINT", "")
c.SwanOauthRenew.files = [
    ("/tmp/swan_oauth.token", "access_token", "{token}"),
    ("/tmp/cernbox_oauth.token", f"exchanged_tokens/"cernbox-service", "{token}"),
    (oauth2_file, f"exchanged_tokens/{eos_oauth_id}", "oauth2:{token}:" + oauth_inspection_endpoint)
]