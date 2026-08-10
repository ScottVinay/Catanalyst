# SCR-007 – Change players

## Purpose and entry

Opened from **Change players** in the Board burger menu. It edits the active colours for the current game.

## Behaviour

- Show all six colours as a multi-select bar with ticks.
- At least one player remains selected.
- Adding a player preserves all existing game state.
- Removing a player removes that player's hand, Analysis plans, roads, settlements, and cities.
- If any such state exists, confirm with `Removing this player will remove their resources, cards, and plans.` and Cancel/Continue.
- Cancel preserves all state; Continue performs the removal.

