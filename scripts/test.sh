#!/usr/bin/env bash
set -euo pipefail

destination="${CATANALYST_DESTINATION:-platform=iOS Simulator,name=iPhone 17,OS=latest}"
derived_data_path="${CATANALYST_DERIVED_DATA_PATH:-/tmp/CatanalystDerivedData}"

test_target() {
    local target="$1"
    xcodebuild test \
        -quiet \
        -project Catanalyst.xcodeproj \
        -scheme Catanalyst \
        -destination "$destination" \
        -derivedDataPath "$derived_data_path" \
        CODE_SIGNING_ALLOWED=NO \
        "-only-testing:$target"
}

# Running the targets independently avoids CoreSimulator Accessibility startup
# races while retaining the complete unit and UI test suites.
test_target CatanalystTests
test_target CatanalystUITests
