#!/bin/bash

set -e

echo "\n[${PIPELINE_BUILD_NUMBER}] Stage: flutter_analyze.sh - pwd"
pwd

echo "\n[${PIPELINE_BUILD_NUMBER}] Stage: flutter_analyze.sh - ls -ld analyze 1"
ls -ld /home/developer

echo "\n[${PIPELINE_BUILD_NUMBER}] Stage: flutter_analyze.sh - ls -ld analyze 2"
ls -ld /home/developer/workspace

echo "\n[${PIPELINE_BUILD_NUMBER}] Stage: flutter_analyze.sh - ls -ld analyze 3"
ls -ld /home/developer/workspace/${JOB_BASE_NAME}

echo "\n[${PIPELINE_BUILD_NUMBER}] Stage: flutter_analyze.sh - ls -ld analyze 4"
ls -ld /home/developer/workspace/${JOB_BASE_NAME}/app

# echo "\n[${PIPELINE_BUILD_NUMBER}] Stage: flutter_analyze.sh - ls -ld analyze 5"
# ls -ld /home/developer/workspace/${JOB_BASE_NAME}/app/packages

# echo "\n[${PIPELINE_BUILD_NUMBER}] Stage: flutter_analyze.sh - ls -ld analyze 6"
# ls -ld /home/developer/workspace/${JOB_BASE_NAME}/app/packages/base_services

# echo "\n[${PIPELINE_BUILD_NUMBER}] Stage: flutter_analyze.sh - ls -ld analyze 7"
# ls -ld /home/developer/workspace/${JOB_BASE_NAME}/app/packages/base_services/lib

flutter analyze
echo "\n[${PIPELINE_BUILD_NUMBER}] Stage: stageInit - After analyze"
