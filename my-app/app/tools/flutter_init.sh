#!/bin/bash

# set -e => exits the script immediately if any command returns a non-zero exit status.
set -e

flutter config --no-analytics

#
# FOR DEBUGGING
#

# echo "[${PIPELINE_BUILD_NUMBER}] Stage: Setup - pwd"
# | /home/developer/workspace/my-app-deploy/app
# pwd
# ls -la

# echo "[${PIPELINE_BUILD_NUMBER}] Stage: Setup - ls -ld user_home"
# ls -ld ${USER_HOME}

# echo "[${PIPELINE_BUILD_NUMBER}] Stage: Setup - ls -ld flutter_home"
# ls -ld ${FLUTTER_HOME}

# echo "[${PIPELINE_BUILD_NUMBER}] Stage: Setup - ls -ld workspace_local"
# ls -ld ${WORKSPACE_LOCAL}

# echo "[${PIPELINE_BUILD_NUMBER}] Stage: stageInit - Begin 1"

#
# INITIALIZE / RESET FLUTTER
#

# Clean Flutter environment
# rm -f app/pubspec.lock
# rm -f app/packages/base_ui/pubspec.lock
# rm -f app/packages/base_services/pubspec.lock

# Remove existing pub cache
# rm -rf ~/.pub-cache

# Repair the pub cache after wiping
# flutter pub cache repair

# You should always run flutter doctor before running `flutter pub get` or `flutter clean`.
# flutter doctor
# echo "[${PIPELINE_BUILD_NUMBER}] Stage: stageInit - After doctor"

#
# INITIALIZE PROJECT
#

flutter clean
# echo "[${PIPELINE_BUILD_NUMBER}] Stage: stageInit - After clean"

flutter pub get
# echo "[${PIPELINE_BUILD_NUMBER}] Stage: stageInit - After pub get"

# very_good update
# echo "[${PIPELINE_BUILD_NUMBER}] Stage: stageInit - After very_good update"

# The recursive option, for some reason, also runs through `.pub-cache`
# (which is strange because that's in the `/home/developer` folder).
# very_good packages get -r
very_good packages get

# In lieu of '-r', add additional packages as needed.
# very_good packages get ./packages/base_services
# very_good packages get ./packages/base_ui

# echo "[${PIPELINE_BUILD_NUMBER}] Stage: stageInit - Done"
