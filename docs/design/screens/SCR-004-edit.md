This screen allows for the editing of a plan. A plan consists of one or more things that are to be built. Actually, there are two kinds of plans. A plan may consist of a set of cards we want to have in our hand, or a set of things that we want to build. When we select new plan, it should first bring up two options, "cards" or "constructions". These options shall be arranged vertically, with Cards above Constructions, rather than side by side. If we click cards, this takes us to screen edit cards. If we click construction, this takes us to screen edit construction.

New Cards plans default to `Card plan N` and new Constructions plans default to `Con plan N`. Each player and plan type has its own sequence, derived from that player's existing saved plans of the same type.

# Cards

At the top left show `ITEM-001-player-selector`.

At the top there is a bar to edit the name of this plan.

Under this there is some helper text that says:

"Plan shall be considered complete when the player's hand contains at least the cards selected."

Under this there is a blank space where selected cards go.

Under this there are, side by side, icons for Brick, Wood, Hay, Sheep, Ore, in that order. See `ITEM-002-cards`. Each of these has a + symbol on it. Tapping one of these adds a copy of this card to the selected cards section.

Copies of the same card in the selected cards section should be stacked, but staggered to the right so we can see how many copies there are.

At the bottom there are two buttons side by side: Cancel and Save

# Constructions


At the top left show `ITEM-001-player-selector`.

At the top right, immediately to the right of the player selector, show the hexagon-cluster button for previewing the current construction plan on the Board.

At the top there is a bar to edit the name of this plan.

Under this there is some helper text that says:

"Plan shall be considered complete when the following have been built in order, starting from the state of the board at the point where the plan is made."

- The construction UI is a series of rows, each representing a step.
- The "new step" row consists of icons side by side for a road, a settlement, and a city. Tapping one of these shows the board, with the title "Placing road", "Placing settlement", or "Placing city".
- Tapping somewhere places a road/settlement/city in that location, but ghostly so we know it is part of the plan only.
- A planned city may only upgrade an existing settlement belonging to the selected player, including a settlement added by an earlier plan step.
- This then goes back to the edit page, where we may select a new item to place, or click cancel/save as usual.
- Note that the ghost items are only available on SCR-004 edit and SCR-005-view-plan, not on SCR-001-board

At the bottom there are two buttons side by side: Cancel and Save
