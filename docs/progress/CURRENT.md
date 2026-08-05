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

- TASK-001 through TASK-030 are implemented and marked `done`.
- Focused simulator/device acceptance checks remain unchecked where explicitly designated for manual verification.
- TASK-029 supersedes custom-plan tap-to-detail behavior: tap expands inline and long press opens SCR-004-edit directly.
- TASK-025 supersedes values-row locking during downward overscroll with native elastic movement and normalized fixed-pane synchronization.

## Completed in this branch

- Completed REQ-015's TASK-025 through TASK-030: elastic values overscroll, construction-editor overflow, All-player custom browsing, independent Plan header buttons, expandable ordered step rows, and five post-completion card-stat rows.
- Added six-slice All-player selection, owner dots, owner-aware filtering/statistics, Red-default creation, and generated-name migration when an untouched new plan changes owner.
- Moved Graph and Help outside the coupled navigation toolbar into distinct 44-point controls with independent press feedback and actions.
- Custom plan taps now animate a shared fixed/value row hierarchy; construction steps precede Brick, Wood, Hay, Sheep, and Ore card-stat rows, while long press edits directly.
- Added deterministic player/hand-aware placeholder models and domain/UI regression coverage for expanded rows and scroll normalization.
- Construction editors now scroll overflowing ordered steps and automatically reveal newly appended rows above the fixed action bar.
- Added six faded, terrain-specific symbols to every hex and reused those mappings in the terrain radial picker.
- Inset the repeated terrain symbols slightly so they no longer touch hex boundaries.
- Shortened valid construction ghost feedback to 0.65 seconds and placed all road layers behind all building layers.
- Added separate graph/help toolbar items with independent pressed states.
- Moved placement errors low on the Board with cancellable 1.5-second replacement timing.
- Increased Detail zoom to 1.85, raised Overview slightly, and layered the movable Board behind fixed controls.
- Restricted planned cities to same-player settlement upgrades, including projected earlier settlements.
- Verified per-player/per-kind plan naming across unrelated names, cancellations, and player changes.
- Reordered the Board bar to Edit–Hand–Plans and added persistent autosaving per-player resource hands.
- Added shared tap-to-remove card stacks and propagated current hands into Plan Browser placeholder inputs.
- Separated the Plans graph/help tap targets, stacked Cards above Constructions, and moved construction preview beside the top player selector.
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
- Increased the fixed Detail zoom level from 1.5 through 1.65 to the current 1.85.
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
- Fixed the active meta-header and embedded its direction arrow; downward values overscroll is now elastic while fixed panes remain normalized.
- Changed placeholder probabilities to monotonic cumulative distributions.
- Added unit and UI coverage for default plan data and sheet presentation.
- Replaced the zoom segmented control with discrete pinch zoom.
- Added bounded detail-mode panning and tap-to-centre behavior.
- Added deterministic radial hit-testing and UI coverage for centre cancellation and drag-to-apply behavior.
- Compile-only `xcodebuild build` and `xcodebuild build-for-testing` checks pass.

## Known blocker

- CoreSimulator remains unreliable. The latest app, unit-test, and UI-test bundles compile successfully, but live focused UI execution is deferred to the user as requested.

## Recommended next action

- On a functioning simulator/device, perform the remaining unchecked focused UI checks, with priority on elastic Plans scrolling, expansion alignment/animation, independent Graph/Help press feedback, and long-press Board gesture arbitration.
