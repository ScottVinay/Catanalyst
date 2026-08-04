status: in-progress
started_datetime: 2026-08-04T18:07:00+01:00
completed_datetime:
priority: P1
requirement: REQ-003
design: SCR-004-edit, SCR-005-view-plan

# Initial custom-plan edit screens

Add `SCR-004-edit` and `SCR-005-view-plan` to the extent specified by their current designs. The original task referenced the old screen numbers; the current design filenames are authoritative.

## Acceptance criteria

- [x] The Custom tab provides a New Plan row.
- [x] New Plan first offers Cards and Constructions choices.
- [x] Both editors show the shared player selector, editable plan name, specified helper text, and Cancel/Save actions.
- [x] The cards editor shows Brick, Wood, Hay, Sheep, and Ore cards side by side with their specified visual treatments.
- [x] Tapping a resource adds a card, and duplicate selected cards are visibly staggered in a stack.
- [x] The constructions editor clearly represents the design's currently unfinished construction UI without inventing construction behavior.
- [x] Saved custom plans appear in the Custom tab for the lifetime of the Plan Browser.
- [x] Holding a custom-plan row opens the initial view-plan screen with its name/icon and an Edit action.
- [x] Custom plans and selected card counts are serializable.
- [ ] Cards in the selected region should have a white outline, so that when they are stacked we can easily see how many of them there are.
- [ ] Focused UI tests pass on a functioning simulator.

## Implementation notes

- `CustomPlan`, `CustomPlanKind`, and `ResourceCard` are value types independent of SwiftUI and conform to `Codable` and `Sendable`.
- `PlanEditorView` supports both current plan kinds; construction steps remain an explicit placeholder because SCR-004 marks that UI TODO.
- `ResourceCardView` preserves poker-card proportions and provides the five design colors/icons.
- Custom plans are deliberately screen-local mock data until a persistent plan store is designed.
- `PlanDetailView` implements only SCR-005's currently specified name/icon and Edit behavior.

## Evidence

- Added `CustomPlanTests` for content, serialization round trips, and invalid-count normalization.
- Added UI scenarios for creating/editing a cards plan and opening the construction placeholder.
- `xcodebuild build-for-testing -quiet -project Catanalyst.xcodeproj -scheme Catanalyst -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/Catanalyst-task008-derived` succeeded for the app and both test bundles.
- All three `CustomPlanTests` passed on the iPhone 17 simulator. The combined run's UI-test launcher then stalled with Xcode's debugger service error and was terminated; the construction UI test was reported failed by the interrupted launcher rather than an assertion.
- A serial `test-without-building` retry avoided simulator clones but failed before either UI test launched because `launchd_sim` crashed and could not bind to the simulator session. No UI assertion failure was reported.

## Remaining risks and manual checks

- Rerun the two focused UI tests after the simulator/debugger service is stable.
- Manually check five-card sizing, stacked-card readability, both Cancel/Save paths, and edit-from-detail presentation on an iPhone-sized screen.
- Persistence outside the presented Plan Browser and construction-step editing remain future work rather than silently expanding this task.
