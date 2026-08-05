# SCR-004 – Edit Analysis item

Analysis opens the appropriate editor directly: Production creates a production check and Plans creates an ordered construction plan. Both editors provide player ownership, an editable generated name, an on-demand 3×3 icon grid, Clear, Cancel, and Save. Changing owner updates an untouched generated name but preserves a user-edited name.

The shared icon choices are cards, hammer, road, settlement, city, target, flag, chart, and hex grid. Production defaults to cards and names `Prod N`; Plans default to hammer and names `Plan N`. Numbering is independent per player and kind.

The current icon sits beside the name with a small pencil affordance. The grid is hidden initially; tapping the icon or pencil reveals it, and choosing an icon automatically collapses it. The name, icon, player selector, and type-specific content scroll together. Clear, Cancel, and Save remain fixed outside the scrolling region.

## Production check

The helper explains that the check completes when the player's hand contains at least the selected cards. Brick, Wood, Hay, Sheep, and Ore add one card. Selected duplicates stack with white outlines; tapping a stack removes one copy. Clear removes all selected cards from the draft.

## Plan

The helper explains that ordered constructions start from the Board state when the plan is made. Existing Road, Settlement, and City steps are ordered rows. The final step may be removed and Clear removes all draft steps.

New-step icons open Board placement with the matching title. Earlier steps are translucent projected pieces. Valid placement shows the new ghost for 0.65 seconds, then returns without mutating the live Board. Roads render behind real and ghost buildings. The preview button remains immediately right of the player selector.

Cancel discards the draft. Save persists its name, owner, icon, and contents in the active game across closing Analysis and application termination.
