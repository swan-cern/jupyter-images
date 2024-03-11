# SWAN Jupyter Docker images

Users' docker images to run Jupyter server with the SWAN environment.

## Custom environments

### Create your environment

The goal of ***makenv*** is to create a virtual environment and install packages from a provided requirements file.

Overall, this script simplifies the process of setting up a virtual environment and installing the required packages, making it easier to manage project dependencies and ensure consistent execution across different environments.

```bash
Usage: makenv --env/-e NAME --req/-r REQUIREMENTS [--accpy ACCPY_VERSION] [--clear] [--no-accpy] [--help/-h]

Options:
  -e, --env NAME              Name of the custom virtual environment (mandatory)
  -r, --req REQUIREMENTS      Path to requirements.txt file or http link for a public repository (mandatory)
  -c, --clear                 Clear the current virtual environment, if it exists
  -h, --help                  Print this help page
  --accpy VERSION             Version of Acc-Py to be used
  --no-accpy                  Use standard Python instead of Acc-Py
```

### Share your environment

1. Create a repository on [Github](https://github.com/new) or [CERN Gitlab](https://gitlab.cern.ch/projects/new) with a requirements.txt file on the root directory.

2. Share the repository URL with your collaborators.

3. Your collaborators can build the environment with the following command:
    ```bash
    makenv --env <NAME> --req <REPOSITORY_URL>
    makenv -e <NAME> -r <REPOSITORY_URL>
    ```

4. Your collaborators can also update the environment by adding, updating or removing packages from the requirements.txt file and pushing the changes to the repository. An **username** and **access token** may be **required**.

5. Later, the `--clear` flag can be used for rebuilding the environment.

6. The `--accpy`flag allows the user to specify the version of Acc-Py to be used. If not specified, the latest version will be used.

7. The `--no-accpy` flag can also be used to create a virtual environment using standard Python, instead of Acc-Py.
