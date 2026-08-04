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

- TASK-008's initial custom-plan edit/detail screens are implemented and remain `in-progress` pending two runtime UI checks.
- TASK-007's shared player selector and piece ownership are implemented and remain `in-progress` pending runtime checks.
- TASK-006's Default Plan Browser is implemented and remains `in-progress` pending runtime checks.
- TASK-002 and TASK-004 are implemented and remain `in-progress` pending their required manual gesture checks.
- TASK-003 number removal is preserved in the tap-based number picker.

## Completed in this branch

- Enabled the Custom plans tab with New Plan type selection, in-memory saved rows, long-press detail, and edit navigation.
- Added serializable custom-plan/card models plus the initial cards and construction editors from SCR-004.
- Added poker-proportioned resource cards, duplicate-card stacking, shared player selection, name editing, and Cancel/Save actions.
- Added the current SCR-005 plan detail scope: icon/name and an Edit action.
- Added six serializable player colours and reusable rightward-expanding player selection on Board and Plans.
- Presented the selector as a fixed-footprint overlay so expansion does not move other content, and limited its Board presence to edit mode.
- Added per-player road/building ownership, rendering, isolation, and backward-compatible decoding.
- Made all six placeholder player profiles meaningfully distinct, with recomputed summary statistics and monotonic probability curves.
- Added a bottom-sheet Default Plan Browser with all nine fixed plan rows.
- Added red deterministic placeholder summary and turn-probability values.
- Added separate fixed plan/header panes synchronized with the clipped values viewport, plus grouped super-column headers and boundary lines.
- Matched fixed/value row metrics, normalized scroll insets, compacted the four summary columns, and slightly strengthened separators.
- Anchored short values content to the top-leading viewport edge so results align with plan rows when the table does not fill the screen.
- Split horizontal navigation into a full-width summary section and a continuously scrollable probability section with animated swipe/chevron transitions.
- Fixed the active meta-header and embedded its direction arrow; counteracted downward overscroll to keep figures locked to plan rows.
- Changed placeholder probabilities to monotonic cumulative distributions.
- Added unit and UI coverage for default plan data and sheet presentation.
- Replaced the zoom segmented control with discrete pinch zoom.
- Added bounded detail-mode panning and tap-to-centre behavior.
- Replaced long-press-and-drag radial editing with tap-to-open and tap-to-apply buttons.
- Added deterministic viewport tests and UI coverage for opening/closing the radial picker.
- Compile-only `xcodebuild build` and `xcodebuild build-for-testing` checks pass.

## Known blocker

- CoreSimulator now lists an iPhone 17, and TASK-008's three unit tests passed. UI launches remain blocked: the parallel run reported `DebuggerVersionStore.StoreError`, while a serial retry failed before testing because `launchd_sim` crashed and could not bind to the simulator session.

## Recommended next action

- Repair the Xcode debugger/simulator service, then run TASK-008's two focused UI tests followed by the outstanding TASK-002, TASK-004, TASK-006, and TASK-007 runtime checks. If they pass, check the final acceptance criteria, set completion timestamps, and mark the tasks `done`.
