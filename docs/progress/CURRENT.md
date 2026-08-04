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

- REQ-013's TASK-013 through TASK-017 are implemented and marked `done`; only the user-owned focused simulator checks remain unchecked as requested.
- TASK-012's completed SCR-004 construction workflow and REQ-012 legality rules are implemented and remain `in-progress` pending runtime UI checks.
- TASK-011's centred controls and contextual help are implemented and remain `in-progress` pending runtime UI checks.
- TASK-010's revised hold-and-drag hex editor is implemented and remains `in-progress` pending its runtime gesture check.
- TASK-009's shared Default/Custom table is implemented and remains `in-progress` pending its runtime UI check.
- TASK-008's initial custom-plan edit/detail screens are implemented and remain `in-progress` pending two runtime UI checks.
- TASK-007's shared player selector and piece ownership are implemented and remain `in-progress` pending runtime checks.
- TASK-006's Default Plan Browser is implemented and remains `in-progress` pending runtime checks.
- TASK-002 remains `in-progress` pending its required manual gesture checks; TASK-004 is done but its tap-picker behavior is superseded by TASK-010.
- TASK-003 number removal is preserved in the hold-and-drag number picker.

## Completed in this branch

- Made custom-plan rows open on tap and corrected detail-to-editor dismissal so Close/Cancel returns to the Plan Browser.
- Added Cards/Constructions Clear actions plus final-construction-step removal with draft-safe Cancel behavior.
- Added cancellable 0.8-second construction-placement ghost feedback and a read-only projected Board preview.
- Added player- and kind-specific automatic `Card plan N` / `Con plan N` names derived from saved plans.
- Extended shared road legality to owned road chains, including planned prior roads, with the revised exact validation message.
- Added ordered, serializable Road/Settlement/City plan steps with a dedicated Board placement screen and translucent prior-step rendering.
- Added shared domain placement rules, projected sequential plan state, and exact two-second REQ-012 errors for Board and plan editing.
- Centred the Terrain/Numbers control independently of its help action and replaced the plan-type action sheet with a centred modal card.
- Added functional circular help controls to Board editing, plan editing, plan-type selection, and Plan Browser.
- Added REQ-011's stationary 0.3-second radial hold, immediate Detail-mode pan arbitration, cancellation cleanup, and outward option animation.
- Ordered Board controls as Terrain/Numbers then Player, and Plans controls as Default/Custom then Player.
- Increased the fixed Detail zoom level from 1.5 to 1.65.
- Replaced the deprecated expanding player control with the current labelled six-colour row and selected-colour tick.
- Reserved identical Board control space in viewing/editing modes so entering edit mode no longer shifts the Board.
- Isolated custom plans by their owning player colour; switching players now swaps the visible custom-plan set.
- Replaced hex tap editing with SCR-001's hold, drag, highlight, and release interaction while preserving zoomed tap-to-centre.
- Reused the full fixed-pane plan table for Custom plans, including compact two-line icon/name rows, red placeholders, and aligned New Plan placement.
- Added white outlines to selected cards so staggered counts remain legible.
- Enabled the Custom plans tab with New Plan type selection, in-memory saved rows, long-press detail, and edit navigation.
- Added serializable custom-plan/card models plus the initial cards and construction editors from SCR-004.
- Added poker-proportioned resource cards, duplicate-card stacking, shared player selection, name editing, and Cancel/Save actions.
- Added the current SCR-005 plan detail scope: icon/name and an Edit action.
- Added six serializable player colours and reusable immediate player selection on Board, Plans, and plan editing.
- Presented the selector as a fixed-footprint overlay and limited its Board presence to edit mode.
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
- Added deterministic radial hit-testing and UI coverage for centre cancellation and drag-to-apply behavior.
- Compile-only `xcodebuild build` and `xcodebuild build-for-testing` checks pass.

## Known blocker

- CoreSimulator now lists an iPhone 17, and TASK-008's three unit tests passed. UI launches remain blocked: the parallel run reported `DebuggerVersionStore.StoreError`, while a serial retry failed before testing because `launchd_sim` crashed and could not bind to the simulator session.

## Recommended next action

- Repair the Xcode debugger/simulator service, then run TASK-008 through TASK-010's focused UI tests followed by the outstanding TASK-002, TASK-006, and TASK-007 runtime checks. If they pass, check the final acceptance criteria, set completion timestamps, and mark the tasks `done`.
