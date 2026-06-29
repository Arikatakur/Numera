#!/bin/sh
# ci_pre_xcodebuild.sh
# Runs before every xcodebuild invocation (both the test run and the archive).
# Use this to set the build number, inject environment-specific values, etc.

set -e

echo "--- Numera pre-xcodebuild ---"
echo "CI_WORKFLOW:       $CI_WORKFLOW"
echo "CI_BUILD_NUMBER:   $CI_BUILD_NUMBER"
echo "CI_BRANCH:         $CI_BRANCH"
echo "CI_COMMIT:         $CI_COMMIT"
echo "CI_PRODUCT_PLATFORM: $CI_PRODUCT_PLATFORM"

# Set the Xcode build number to the Xcode Cloud build number.
# This ensures every TestFlight build has a unique, incrementing CFBundleVersion.
if [ -n "$CI_BUILD_NUMBER" ]; then
  echo "Setting CFBundleVersion to $CI_BUILD_NUMBER"
  /usr/libexec/PlistBuddy \
    -c "Set :CFBundleVersion $CI_BUILD_NUMBER" \
    "$CI_PRIMARY_REPOSITORY_PATH/Numera/Resources/Info.plist" 2>/dev/null || \
  agvtool new-version -all "$CI_BUILD_NUMBER"
fi
