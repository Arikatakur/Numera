#!/bin/sh
# ci_post_xcodebuild.sh
# Runs after every xcodebuild invocation.
# Use this to print test results, collect artifacts, or send notifications.

set -e

echo "--- Numera post-xcodebuild ---"

# Print test result summary if this was a test run
if [ "$CI_XCODEBUILD_ACTION" = "test" ]; then
  echo "Test action completed."
  if [ -d "$CI_RESULT_BUNDLE_PATH" ]; then
    echo "Result bundle: $CI_RESULT_BUNDLE_PATH"
  fi
fi

# Print archive path if this was an archive (deploy) run
if [ "$CI_XCODEBUILD_ACTION" = "archive" ]; then
  echo "Archive completed."
  if [ -d "$CI_ARCHIVE_PATH" ]; then
    echo "Archive path: $CI_ARCHIVE_PATH"
  fi
fi

echo "Build complete."
