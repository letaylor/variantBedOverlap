#!/bin/bash
#===============================================================================
#title        :deploy_anaconda.sh
#description  :Automatic Uploads to Anaconda from Travis CI
#author       :Leland Taylor
#date         :26/03/2019
#version      :0.1
#usage        :sh deploy_anaconda.sh PKG_NAME
#input        :PKG_NAME (required)
#               - path of package to deploy
#output       :NULL
#notes        :CONDA_USER_NAME is stored securely in on Travis CI.
#              CONDA_UPLOAD_TOKEN is stored securely in on Travis CI.
#              See README.md
#===============================================================================
set -e

CONDA_OUT_FILE=${1-"ERROR"} # for conda build .
#echo "CONDA_OUT_FILE=${CONDA_OUT_FILE}"

# By adding --all to anaconda call, automatically run the conda convert
# echo "Converting conda package..."
# conda convert --platform all ${CONDA_OUT_FILE} --output-dir conda-bld/

echo "Deploying to Anaconda.org..."
anaconda --token ${CONDA_UPLOAD_TOKEN} upload \
    ${CONDA_OUT_FILE} \
    --user ${CONDA_USER_NAME} \
    --label "main" \
    --force \
    --all

echo "Successfully deployed to Anaconda.org."
exit 0
