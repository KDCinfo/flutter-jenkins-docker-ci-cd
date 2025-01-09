#!/bin/bash

set -e
# set -x

# Purpose: When a decision is made to release the app,
#          this script will merge the 'main' branch into the
#          'build_release' branch and trigger a Jenkins build.
#
# How it works:
# - Prompt to update the version in pubspec.yaml and release-notes.txt.
#   - Commit changed files, if any, back to 'main'.
# - Merge 'main' into 'build_release'.
# - Prompt user to trigger a Jenkins build for 'build_release'.
#
# Usage:
# > ./rund.sh
# > ./rund.sh v  # Skip versioning and merging; just trigger the Jenkins build.

# Configuration
PUBSPEC_FILE="../pubspec.yaml"
RELEASE_NOTES_FILE="../release-notes.txt"
MAIN_BRANCH="main"
RELEASE_BRANCH="build_release"

echo "pwd: $(pwd)"

# Set Jenkins API credentials
#
JENKINS_URL="http://localhost:8080"
JOB_NAME="my-app-deploy"
TOKEN_FILE_PATH="../../../src/keys/"
TOKEN_FILE="${TOKEN_FILE_PATH}secretjenkinsapikey"

# The following '{ read }' will populate the 'token' variable
#   whether the 'read' is successful or not.
# If the 'read' is called directly, the script can potentially
#   fail silently on the read itself.
# Background:
#   This 'read -r' command was borrowed from another script where
#     the 'read' was actually failing silently, but it wasn't known
#     because the 'token' variable was still being populated, and
#     because 'set -e' wasn't set in that script, the failure,
#     despite being silent, didn't stop the script.
#   Adding a carriage return to the end of the secret file eventually fixed it,
#     but in the case that it could happen again, this approach won't kill the script,
#     should there be a problem with the file, even with the 'set -e' flag set above.
echo "Reading Jenkins API token..."
{ read -r token < "${TOKEN_FILE}"; } && \
    echo "Token read successfully!" || \
    echo "Read failed with exit code $?"

API_TOKEN="$token"
API_USER="auser"

# Get the last build number from the Jenkins API
function get_last_build_number() {

    # Query the Jenkins API to get the last build number
    LAST_JENKINS_BUILD_NUMBER=$(curl -s -u "$API_USER:$API_TOKEN" "$JENKINS_URL/job/$JOB_NAME/lastBuild/buildNumber")

    # Return the last build number
    echo "$LAST_JENKINS_BUILD_NUMBER"
}

# Increment the version number
function increment_version() {
    IFS='.' read -r -a version_parts <<< "$1"
    version_parts[2]=$((version_parts[2] + 1)) # Increment the patch version
    echo "${version_parts[0]}.${version_parts[1]}.${version_parts[2]}"
}

# Update pubspec.yaml and release-notes.txt
function update_files() {
    NEW_MMP_VERSION=$1
    PUBSPEC_BUILD_NUM=$2
    JENKINS_BUILD_NUM=$3
    NEW_RELEASE_NOTES=$4

    # Compute new version: 1.2.3+4 -> 1.2.3+5
    NEW_VERSION="$NEW_MMP_VERSION+$((PUBSPEC_BUILD_NUM + 1))"

    echo "Updating $PUBSPEC_FILE..."
    echo "New version: $NEW_VERSION"

    # Note on 'sed': The empty [-i ''] flag only works on BSD sed (macOS).

    # Update the version in pubspec.yaml
    sed -i '' "s/^version: .*/version: $NEW_VERSION/" "$PUBSPEC_FILE"

    # Replace the first instance of '(TBA)' with the last Jenkins build number
    echo "Replacing the first instance of '(TBA)' with last Jenkins build number ($3) in $RELEASE_NOTES_FILE..."
    sed -i '' "1,/(TBA)/s/(TBA)/($JENKINS_BUILD_NUM)/" "$RELEASE_NOTES_FILE"

    # Construct the new release notes as a properly escaped multiline string
    echo "Adding new release notes to: $RELEASE_NOTES_FILE"

    NEW_RELEASE_NOTES_WITH_HEADING=$(printf "# version: $NEW_VERSION (TBA)\n$NEW_RELEASE_NOTES\n")

    # Escape newlines for BSD sed
    ESCAPED_NEW_RELEASE_NOTES=$(echo "$NEW_RELEASE_NOTES_WITH_HEADING" | sed 's/$/\\/' | sed '$ s/\\$//' && echo)

    # Insert the escaped new release notes above only the first '# version:' line
    sed -i '' "1,/^# version:/s/^# version:/$ESCAPED_NEW_RELEASE_NOTES\\
\\
&/" "$RELEASE_NOTES_FILE"

    echo "Updated 'release-notes.txt' with new release notes."

    echo "Updated '$PUBSPEC_FILE' and '$RELEASE_NOTES_FILE' with new version and release notes."
}

# Step 1: Check if required files are updated
function check_updates() {
    echo "Checking for updates in $PUBSPEC_FILE and $RELEASE_NOTES_FILE"

    # Extract the current version (with '(TBA)') from pubspec.yaml.
    PUBSPEC_VERSION=$(grep '^version:' $PUBSPEC_FILE | awk '{print $2}')
    PUBSPEC_MAJ_MIN_PATCH=$(echo "$PUBSPEC_VERSION" | cut -d '+' -f1)
    PUBSPEC_BUILD_NUM=$(echo "$PUBSPEC_VERSION" | cut -d '+' -f2)

    RELEASE_NOTES_LAST_BUILD_NUM=$(grep -E '^# version:' $RELEASE_NOTES_FILE | sed -n '1,/^# version:/s/.*(\([0-9]*\)).*/\1/p')
    RELEASE_NOTES_LAST_VERSION=$(grep '^# version:' $RELEASE_NOTES_FILE | head -n 1 | awk '{print $3}' | cut -d '+' -f1)

    JENKINS_LAST_BUILD_NUMBER=$(get_last_build_number)

    echo "PUBSPEC_VERSION: $PUBSPEC_VERSION"
    echo "PUBSPEC_MAJ_MIN_PATCH: $PUBSPEC_MAJ_MIN_PATCH"
    echo "PUBSPEC_BUILD_NUM: $PUBSPEC_BUILD_NUM"
    echo "RELEASE_NOTES_LAST_BUILD_NUM: $RELEASE_NOTES_LAST_BUILD_NUM"
    echo "RELEASE_NOTES_LAST_VERSION: $RELEASE_NOTES_LAST_VERSION"
    echo "JENKINS_LAST_BUILD_NUMBER: $JENKINS_LAST_BUILD_NUMBER"

    # We can check the last release notes build number with the last successful build number in Jenkins.
    #   If they're the same, ask the user to confirm that the version has already been updated.
    #   If they're different, we can ask the user to provide the new (x.y.z) version
    #     (the Pubspec '+build' will always just be incremented from the last build).

    LAST_SUCCESSFUL_BUILD_NUMBER=$(curl -s -u "$API_USER:$API_TOKEN" "$JENKINS_URL/job/$JOB_NAME/api/json" | jq '.lastSuccessfulBuild.number')
    echo "Last successful build number: $LAST_SUCCESSFUL_BUILD_NUMBER"

    ASK_USER_INPUT=false
    if [[ "$RELEASE_NOTES_LAST_BUILD_NUM" == "$LAST_SUCCESSFUL_BUILD_NUMBER" ]]; then
        echo "The last successful Jenkins build number is already in $RELEASE_NOTES_FILE. "
        echo "To confirm the pubspec version and release notes have already been updated "
        echo "and continue with the merge from '$MAIN_BRANCH' to '$RELEASE_BRANCH', press ENTER."
        read -p "Otherwise, type 'v' to update the version and add new release notes: " -n 1 -r
        if [[ $REPLY =~ ^[Vv]$ ]]; then
            ASK_USER_INPUT=true
        fi
    else
        ASK_USER_INPUT=true
    fi

    if [[ "$ASK_USER_INPUT" == true ]]; then
        # We need input from the user:
        # - The new version (x.y.z) to update in pubspec.yaml (the build number will be incremented).
        # - One user input line for each bullet point in release-notes.txt (an empty enter will end the input).

        echo "To update the pubspec version and release-notes, "
        echo "please provide the app's new version and release notes."
        while true; do
            read -r -p "New version (x.y.z): " USER_NEW_VERSION
            [[ $USER_NEW_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] && break
            echo "Please enter a valid version number (x.y.z)."
        done

        echo "Please provide the release notes for the new version."
        echo "Press Enter after each bullet point. Press Enter twice to finish."

        NEW_USER_RELEASE_NOTES=""
        empty_line_count=0

        while IFS= read -r line; do
            # Check if the user pressed Enter (empty input)
            if [[ -z $line ]]; then
                ((empty_line_count++))
                # Break the loop if Enter is pressed twice
                if [[ $empty_line_count -eq 2 ]]; then
                    break
                fi
            else
                empty_line_count=0  # Reset empty line count if input is not empty
                NEW_USER_RELEASE_NOTES+="$line\n"
            fi
        done

        # If NEW_USER_RELEASE_NOTES is empty, skip the update and exit.
        if [[ -z "$NEW_USER_RELEASE_NOTES" ]]; then
            echo "No release notes provided. Exiting..."
            exit 1
        fi

        # Update the files
        update_files "$USER_NEW_VERSION" "$PUBSPEC_BUILD_NUM" "$JENKINS_LAST_BUILD_NUMBER" "$NEW_USER_RELEASE_NOTES"

        # echo commented vars for testing
        echo "PUBSPEC_FILE: $PUBSPEC_FILE"
        echo "RELEASE_NOTES_FILE: $RELEASE_NOTES_FILE"
        echo "USER_NEW_VERSION: $USER_NEW_VERSION"
        echo "MAIN_BRANCH: $MAIN_BRANCH"

        # Commit the changes to 'main'
        git add $PUBSPEC_FILE $RELEASE_NOTES_FILE
        git commit -m "Updated version to $USER_NEW_VERSION | Added release notes."
        git push origin $MAIN_BRANCH

        echo "Files have been updated and committed back to 'main': proceeding with the merge."
    else
        echo "Files were already updated: proceeding with the merge."
    fi
}

# Step 2: Merge main into build_release
function merge_branches() {
    echo "Ensuring we're on the $MAIN_BRANCH branch..."
    git checkout $MAIN_BRANCH
    git pull origin $MAIN_BRANCH

    echo "Merging $MAIN_BRANCH into $RELEASE_BRANCH..."
    git checkout $RELEASE_BRANCH
    git pull origin $RELEASE_BRANCH
    # --no-edit skips the commit message prompt
    git merge $MAIN_BRANCH --no-edit

    echo "Pushing changes to $RELEASE_BRANCH..."
    git push origin $RELEASE_BRANCH
    echo "Merge complete!"

    # Return to the main branch
    git checkout $MAIN_BRANCH
}

# Step 3: Trigger a Jenkins build
function trigger_jenkins_build() {
    echo "Triggering Jenkins build for: $JOB_NAME"

    # http://localhost:8080/job/my-app-deploy/
    # echo "Jenkins URL: $JENKINS_URL"
    # echo "Job Name: $JOB_NAME"
    # FULL_URL="$JENKINS_URL/job/$JOB_NAME/buildWithParameters"
    FULL_URL="$JENKINS_URL/job/$JOB_NAME/build"
    echo "Full URL: $FULL_URL"
    # echo "Release Branch: $RELEASE_BRANCH"

    # Jenkins URL: http://localhost:8080
    # Job Name: my-app-deploy
    # Full URL: http://localhost:8080/job/my-app-deploy/buildWithParameters
    # Release Branch: build_release

    curl -X POST "$FULL_URL" \
        --user "$API_USER:$API_TOKEN"

    echo "Jenkins build triggered."
}

# Main script flow
# If a parameter is not passed, run all calls,
#   else, only run 'trigger_jenkins_build'
#   E.g., './rund.sh j' will only run 'trigger_jenkins_build'
if [[ $# -eq 0 ]]; then
    echo "----- No arg was provided: running updates and merge before triggering the build..."
    echo "----- Running check_updates..."
    check_updates
    echo "----- Running merge_branches..."
    merge_branches
fi
echo "----- Running trigger_jenkins_build..."
trigger_jenkins_build
