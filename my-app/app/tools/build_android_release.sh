#!/bin/bash

set -e

# Set HOME explicitly if not set
export HOME=${HOME:-/home/developer}

flutter config --no-analytics

# Archive APK with versioned name
ARCHIVE_PATH="./android/fastlane/archive"
mkdir -p ${ARCHIVE_PATH}
rm -f ${ARCHIVE_PATH}/*

# Examples:
# JOB_BASE_NAME my-app-deploy
# BUILD_NUMBER  # 179
# MMP_VERSION   # 1.2.7
# NEW_VERSION   # 1.2.7+179
echo "BUILDING (android) --- JOB_BASE_NAME: ${JOB_BASE_NAME}"
echo "BUILDING (android) --- BUILD_NUMBER: ${BUILD_NUMBER}"
echo "BUILDING (android) --- PIPELINE_BUILD_NUMBER: ${PIPELINE_BUILD_NUMBER}"
echo "BUILDING (android) --- MMP_VERSION: ${MMP_VERSION}"
echo "BUILDING (android) --- NEW_VERSION: ${NEW_VERSION}"

# Build APK
flutter build appbundle -t lib/app/app_bootstrap/main_prod.dart --release \
  --build-name="${MMP_VERSION}" --build-number="${BUILD_NUMBER}" \
  --obfuscate --split-debug-info=build/app/outputs/symbols/
#   --no-tree-shake-icons \

# BUILD_NAME="my-app-deploy"
BUILD_NAME=${JOB_BASE_NAME}
AAB_NAME="${BUILD_NAME}-release.aab"
export AAB_NAME="${AAB_NAME}"

# https://docs.fastlane.tools/actions/supply/#changelogs-whats-new
# https://developer.android.com/studio/publish/versioning#appversioning
# versionCode: A positive integer used as an internal version number.
export APP_VERSION_CODE="${BUILD_NUMBER}"

mv build/app/outputs/bundle/release/app-release.aab ${ARCHIVE_PATH}/"${AAB_NAME}"

#
# RELEASE NOTES
#

write_changelog() {
  # Define variables
  RELEASE_NOTES_SRC="./release-notes.txt"  # Source file with all release notes
  BUILD_VERSION="${BUILD_NUMBER}"          # Current build number (from Jenkins)
  CHANGELOG_FILENAME="${BUILD_VERSION}.txt"  # Changelog file, e.g., 176.txt
  CHANGELOG_DEST="./android/fastlane/metadata/android/en-US/changelogs/${CHANGELOG_FILENAME}"

  # Ensure release-notes.txt exists
  if [[ ! -f "${RELEASE_NOTES_SRC}" ]]; then
    echo "Error: ${RELEASE_NOTES_SRC} does not exist!"
    exit 1
  fi

  # Extract the changelog for the current version marked with (TBA)
  # - Find the lines after "(TBA)" and stop at the next "# version"
  CHANGELOG_CONTENT=$(awk '
    BEGIN { capture = 0 }
    /TBA/ { capture = 1; next }
    /^#/ { if (capture) exit }
    capture { print }
  ' "${RELEASE_NOTES_SRC}")

  # Ensure changelog content was found
  if [[ -z "${CHANGELOG_CONTENT}" ]]; then
    echo "Error: No changelog found for version marked with (TBA) in ${RELEASE_NOTES_SRC}."
    exit 1
  fi

  # Create the destination folder if it doesn't exist
  mkdir -p "$(dirname "${CHANGELOG_DEST}")"

  # Write the changelog content to the destination file
  echo "${CHANGELOG_CONTENT}" > "${CHANGELOG_DEST}"

  # Output success message
  echo "Changelog for build ${BUILD_VERSION} written to: ${CHANGELOG_DEST}"
}

# Copy release-notes.txt to fastlane
#
# 1) Read file: release-notes.txt
# 2) Create new file (VER_REL_NOTES_FILE)
#      with all the lines after "(TBA)" and before the next "# version"
# 3) Copy to VER_REL_NOTES_DEST.
#
VER_REL_NOTES_FILE="${BUILD_NUMBER}.txt"  # 149.txt
VER_REL_NOTES_DEST="./android/fastlane/metadata/android/en-US/changelogs/${VER_REL_NOTES_FILE}"

write_changelog

# cat build/app/outputs/mapping/release/missing_rules.txt

# Deploy to Google Play using Fastlane
# FASTLANE_JSON_KEY_PATH="/path/to/your/fastlane-api-key.json" # Adjust this path as needed
FASTLANE_JSON_KEY_PATH="${GOOGLE_PLAY_JSON_TOKEN_MY_APP}"
export GOOGLE_APPLICATION_CREDENTIALS="${FASTLANE_JSON_KEY_PATH}"

cd ./android/fastlane

# Call Fastlane to upload to Play Store
bundle exec fastlane android deploy_to_play_store
# bundle exec fastlane supply \
#   --apk "./archive/${AAB_NAME}" \
#   --track "beta" \
#   --json_key "${FASTLANE_JSON_KEY_PATH}"
