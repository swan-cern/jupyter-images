#!/bin/bash

# Author: Danilo Piparo, Enric Tejedor, Pedro Maximino, Diogo Castro 2023
# Copyright CERN
# The environment for Spark is configured here. It allows CERN users to
# connect to spark clusters and use their computational resources
# through SWAN.

if [[ -n $SPARK_CLUSTER_NAME ]]
then
   _log "Configuring Spark";

  LOCAL_IP=`hostname -i`
  echo "$LOCAL_IP $SERVER_HOSTNAME" >> /etc/hosts

  # Enable the extensions in Jupyter global path to avoid having to maintain this information 
  # in the user scratch json file (specially because now we persist this file in the user directory and
  # we don't want to persist the Spark extensions across sessions)
  _log "Globally enabling the Spark extensions"
  # Ensure nb configuration directory is created.
  NBCONFIG=/etc/jupyter/nbconfig/notebook.d
  mkdir -p $NBCONFIG

  jq -n --argjson sparkconnector/extension true \
        --argjson sparkmonitor/extension true \
        '{load_extensions: $ARGS.named}' > $NBCONFIG/spark.json

  IPYTHON_KERNEL_CONFIG=$IPYTHONDIR/profile_default/ipython_kernel_config.py

  echo -e "c.InteractiveShellApp.extensions.append('sparkmonitor.kernelextension')\n$( [ -f ${IPYTHON_KERNEL_CONFIG} ] && cat ${IPYTHON_KERNEL_CONFIG})" > ${IPYTHON_KERNEL_CONFIG}
  echo -e "c.InteractiveShellApp.extensions.append('sparkconnector.connector')\n$( [ -f ${IPYTHON_KERNEL_CONFIG} ] && cat ${IPYTHON_KERNEL_CONFIG})" > ${IPYTHON_KERNEL_CONFIG}

  # Configure the Hadoop and Spark related environment
  CVMFS_BUNDLES_PATH="$(dirname $SPARK_CONFIG_SCRIPT)/bundles"
  if [ "$SOFTWARE_SOURCE" == "lcg" ]; then
    # Source configuration for selected cluster
    # Detect Spark major from spark-submit and set SPARKVERSION to "spark3", "spark4" or ""
    SPARKVERSION=""
    if [ -L "$LCG_VIEW/bin/spark-submit" ] || [ -x "$LCG_VIEW/bin/spark-submit" ]; then
      # Resolve final target of the symlink
      target=$(readlink -f "$LCG_VIEW/bin/spark-submit")
      # Extract the Spark version (e.g., 4.0.1 from paths like .../spark/4.0.1-abcde/)
      version=$(echo "$target" | sed -n 's#.*/spark/\([0-9]\+\.[0-9]\+\.[0-9]\+\).*#\1#p')
      # Extract the major number
      major=$(echo "$version" | cut -d. -f1)
      case "$major" in
        3) SPARKVERSION="spark3" ;;
        4) SPARKVERSION="spark4" ;;
      esac
    else
      echo "Error: $LCG_VIEW/bin/spark-submit not found." >&2
    fi
    HADOOPVERSION='3.3'   # Classpath compatibility for YARN
    source $SPARK_CONFIG_SCRIPT $SPARK_CLUSTER_NAME $HADOOPVERSION $SPARKVERSION
    # Make the extraJavaOptions option in the NXCALS TESTBED bundle available to SparkConnector
    ln -s $CVMFS_BUNDLES_PATH/bundles.json $JUPYTER_CONFIG_DIR/nbconfig/sparkconnector_bundles.json
  else
    mkdir -p $JUPYTER_CONFIG_DIR/nbconfig
    # Make the NXCALS TESTBED bundle available to SparkConnector
    jq '{ bundled_options: { NXCALS_TESTBED: { options: [.bundled_options.NXCALS_TESTBED.options[] | select(.name == "spark.driver.extraJavaOptions")] } } }' ${CVMFS_BUNDLES_PATH}/bundles.json > $JUPYTER_CONFIG_DIR/nbconfig/sparkconnector_bundles.json
  fi
  # Make the Spark options available to SparkConnector
  ln -s $CVMFS_BUNDLES_PATH/spark_options.json $JUPYTER_CONFIG_DIR/nbconfig/sparkconnector_spark_options.json
else
  # Disable spark jupyterlab extensions enabled by default if no cluster is selected
  mkdir -p /etc/jupyter/labconfig
  jq -n --argjson @swan-cern/sparkconnector true \
        --argjson jupyterlab_sparkmonitor true \
        '{disabledExtensions: $ARGS.named}' > /etc/jupyter/labconfig/page_config.json
  _log "Skipping Spark configuration";
fi
