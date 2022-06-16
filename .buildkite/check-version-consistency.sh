#!/bin/bash -eu

SRC_FILE=Sources/Model/ObjC/Constants/TracksConstants.m
PODSPEC_FILE=Automattic-Tracks-iOS.podspec

# Workaround for https://github.com/Automattic/buildkite-ci/issues/79
gem install bundler

SOURCE_VERS=$(sed -n s/'^.* TracksLibraryVersion = @"\(.*\)";.*$'/'\1'/p $SRC_FILE)
POD_VERS=$(sed -n s/'^ *s.version *= \([^ ]*\).*$'/'\1'/p $PODSPEC_FILE | tr -d \'\")

echo Version found in $SRC_FILE: $SOURCE_VERS
echo Version found in $PODSPEC_FILE: $POD_VERS
if [ "$SOURCE_VERS" = "$POD_VERS" ]; then
  echo "🎉 Version values match"
else
  echo "Version values differ! Please fix by making sure the 2 files have matching values for the version."
  exit 1
fi
