import os

home = os.environ.get("HOME")
jupyter_path = os.environ.get("JUPYTER_PATH", f"{home}/.local/share/jupyter")
eos_enabled = os.environ.get("EOS_ENABLED", "true").lower() == "true"
local_home = os.environ.get("LOCAL_HOME", "false").lower() == "true"
use_jupyterlab = os.environ.get('SWAN_USE_JUPYTERLAB', 'false').lower() == 'true'

c.NotebookNotary.db_file = f"{jupyter_path}/nbsignatures.db"
c.NotebookNotary.secret_file = f"{jupyter_path}/notebook_secret"

# Configure start directory
if eos_enabled and not local_home and use_jupyterlab:
    # Case 1: JupyterLab with EOS enabled and user home is "/eos/user/<letter>/<username>"
    # In this case, set the root_dir to "/eos" and the preferred_dir to the user home,
    # so that the user sees their home when they open Jupyter but can also easily navigate to other parts of EOS.
    c.ServerApp.root_dir = '/eos'
    c.FileContentsManager.preferred_dir = home
else:
    # Case 2: Either classic UI is selected, EOS is disabled or $HOME is not on EOS
    # In this case, just set the root_dir to the user home.
    c.ServerApp.root_dir = home

c.ServerApp.contents_manager_class = "swancontents.filemanager.SwanEosFileManager"
# To allow deleting Projects, which are never empty because of .swancontents
c.FileContentsManager.always_delete_dir = True

cernbox_oauth_id = os.environ.get("CERNBOX_OAUTH_ID", "cernbox-service")
eos_oauth_id = os.environ.get("EOS_OAUTH_ID", "eos-service")
oauth2_file = os.environ.get("OAUTH2_FILE", "")
oauth_inspection_endpoint = os.environ.get("OAUTH_INSPECTION_ENDPOINT", "")
c.SwanOauthRenew.files = [
    ("/tmp/swan_oauth.token", "access_token", "{token}"),
]

if eos_enabled:
    # Add EOS and CERNBox token renewal when EOS is enabled
    c.SwanOauthRenew.files.extend([
        ("/tmp/cernbox_oauth.token", f"exchanged_tokens/{cernbox_oauth_id}", "{token}"),
        (oauth2_file, f"exchanged_tokens/{eos_oauth_id}", "oauth2:{token}:" + oauth_inspection_endpoint),
    ])

# Toggle JupyterLab based on user preference
if use_jupyterlab or not eos_enabled:
    c.ServerApp.default_url = '/lab'
else:
    c.ServerApp.default_url = '/projects'

user = os.environ.get('USER')
# Change the HOME environment variable to the local user home instead of EOS
# to prevent xelatex from touching EOS during the PDF conversion and so
# reduce the time it takes to convert a PDF (including preventing timeouts).
c.PDFExporter.latex_command = ['env', f'HOME=/home/{user}' , 'xelatex', '-quiet', '{filename}']

# Disable authentication for the /metrics endpoint so that Prometheus
# is able to scrape the user session metrics without requiring the
# authentication token that is only available inside the user session
# pod (and so Prometheus cannot access it). Network policies still
# enforce traffic restrictions.
c.ServerApp.authenticate_prometheus = False
