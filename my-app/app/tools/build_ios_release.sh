#!/bin/bash

set -e

# Archive IPA with versioned name
BUILD_PATH="./build/ios"
IPA_PATH="${BUILD_PATH}/ipa"
SYMBOLS_PATH="${BUILD_PATH}/symbols/"
FASTLANE_PATH="./ios/fastlane"
ARCHIVE_PATH="${FASTLANE_PATH}/archive"
mkdir -p ${ARCHIVE_PATH}
rm -f ${ARCHIVE_PATH}/*

# JOB_BASE_NAME my-app-deploy
# BUILD_NUMBER  # 179
# MMP_VERSION   # 1.2.7
# NEW_VERSION   # 1.2.7+179
echo "BUILDING (ios) --- JOB_BASE_NAME: ${JOB_BASE_NAME}"
echo "BUILDING (ios) --- BUILD_NUMBER: ${BUILD_NUMBER}"
echo "BUILDING (ios) --- APP_BUILD_NUMBER: ${APP_BUILD_NUMBER}"
echo "BUILDING (ios) --- MMP_VERSION: ${MMP_VERSION}"
echo "BUILDING (ios) --- NEW_VERSION: ${NEW_VERSION}"

# This isn't necessary; Jenkins will provide the API key as a secret file.
# Required to unlock the keychain, otherwise we can't access the cert to sign
# echo "### Unlocking keychain..."
# security unlock-keychain -p ${KEYCHAIN_PASSWORD}

# Need the fastlane API Key to deploy to Testflight
# This is set in the Jenkinsfile environment variables.
if [[ -z "${APP_STORE_CONNECT_API_KEY}" ]]; then
  echo "Error: APP_STORE_CONNECT_API_KEY is not set."
  exit 1
fi
echo "### Copying App Store Connect API key..."
cp -f ${APP_STORE_CONNECT_API_KEY} ${FASTLANE_PATH}/app_store_connect_api_key.p8

# Export the build to archive to be exported and signed later by fastlane
echo "### Xcode Building and Archiving..."
flutter --version
which flutter

flutter build ipa --release --flavor="production" \
  --target=lib/app/app_bootstrap/main_prod.dart \
  --build-name="${MMP_VERSION}" --build-number="${APP_BUILD_NUMBER}" \
  --obfuscate --split-debug-info="${SYMBOLS_PATH}"

# BUILD_NAME="my-app-deploy"
BUILD_NAME=${JOB_BASE_NAME}
IPA_NAME_INITIAL="My-App.ipa"
# IPA_NAME="My-App-${NEW_VERSION}.ipa"
IPA_NAME_TARGET="production.ipa"
export IPA_NAME="${IPA_NAME_TARGET}"
export APP_VERSION_CODE="${NEW_VERSION}"
mv "${IPA_PATH}/${IPA_NAME_INITIAL}" "${ARCHIVE_PATH}/${IPA_NAME_TARGET}"

echo "Archive path: ${ARCHIVE_PATH}"
echo "Archive path contents:"
ls -la ${ARCHIVE_PATH}

# Run fastlane in the ios directory
pushd ios

echo "fastlane path contents:"
# Should be in the ios directory
ls -la .
# Should have the key
ls -la ./fastlane
# Should have the ipa
ls -la ./fastlane/archive

# Deploy to Testflight
echo "### Deploying IPA to Test Flight..."
bundle exec fastlane ios deploy_to_testflight ipa_path:"${ARCHIVE_PATH}/${IPA_NAME_TARGET}"

popd
