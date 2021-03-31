#!/bin/bash

set -eo pipefail

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ROOT_DIRECTORY="${SCRIPT_DIRECTORY}/.."

PROJECT_PATH="${ROOT_DIRECTORY}/ios/Stuff.xcodeproj"

# macOS
xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme Bookmarks \
    clean build test | xcpretty

# iOS
xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme Stuff \
    clean build test | xcpretty
