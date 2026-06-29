#!/bin/sh
# ci_post_clone.sh
# Runs once after Xcode Cloud clones the repo.
# Use this to install any tools or dependencies the build needs.
# For Numera (no SPM dependencies, no CocoaPods) this is mostly a no-op,
# but it's the right place to add things later.

set -e

echo "--- Numera post-clone ---"
echo "Xcode version: $(xcodebuild -version)"
echo "macOS version: $(sw_vers -productVersion)"
echo "Working directory: $(pwd)"
