# SWAN Jupyter Docker images

Users' docker images to run Jupyter server with the SWAN environment.

## Custom environments

### Create your environment

```bash
Usage: makenv --name NAME --req REQUIREMENTS [--clear] [--help/-h]

Options:
  -n, --name NAME             Name of the custom virtual environment (mandatory)
  -r, --req REQUIREMENTS      Path to requirements.txt file or http link for a public repository (mandatory)
  -c, --clear                 Clear the current virtual environment if it exists
  -h, --help                  Print this help page
```

### Share your environment

1. Create a repository on [Github](https://github.com/new) or [CERN Gitlab](https://gitlab.cern.ch/projects/new) with a requirements.txt file on the root directory.

2. Share the repository URL with your collaborators.

3. Your collaborators can build the environment with the following command:
    ```bash
    makenv --name <NAME> --req <REPOSITORY_URL>
    ```

4. Your collaborators can also update the environment by adding, updating or removing packages from the requirements.txt file and pushing the changes to the repository. An **username** and **access token** may be **required**.

5. Later, the `--clear` flag can be used for rebuilding the environment.
