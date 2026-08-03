# Current Progress

This should answer: "If a new AI agent starts work right now, what do they need to know that isn't obvious from the code?"

Unlike the other documents, it is temporary and constantly overwritten. It is not part of the permanent project documentation.

It should contain things like:

Current task
What's already been completed in this branch
What's left to do
Known blockers
Anything important the next coding session should know
The recommended next action

Use the area below the three dashes for your current notes:

---

## Current work

- TASK-002 and TASK-004 are implemented and remain `in-progress` pending their required manual gesture checks.
- TASK-003 number removal is preserved in the tap-based number picker.

## Completed in this branch

- Replaced the zoom segmented control with discrete pinch zoom.
- Added bounded detail-mode panning and tap-to-centre behavior.
- Replaced long-press-and-drag radial editing with tap-to-open and tap-to-apply buttons.
- Added deterministic viewport tests and UI coverage for opening/closing the radial picker.
- Compile-only `xcodebuild build` and `xcodebuild build-for-testing` checks pass.

## Known blocker

- CoreSimulator still hangs while launching test workers, consistent with the saved AccessibilityUIServer crash. On 2026-08-03, focused combined and unit-only `xcodebuild test` runs built successfully but waited indefinitely for workers to materialize; `xcrun simctl list devices` also hung.

## Recommended next action

- Restart or repair CoreSimulator, run the focused viewport and tap-selection tests, and manually check pinch, pan, centring, and radial selection. If they pass, check the final acceptance criteria, set completion timestamps, and mark TASK-002 and TASK-004 `done`.
