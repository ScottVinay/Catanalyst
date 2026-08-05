# SCR-006 – Cards in Hand

## Purpose

This screen assigns the resource cards currently held by each player. Stored hands are persistent game-state inputs used when calculating values in the Plan Browser.

## Entry and presentation

- Open this screen from the middle **Hand** button in the Board bottom bar defined by TASK-023.
- Present it as a large bottom sheet, matching the Plan Browser presentation.
- The title is **Cards in hand**.
- Provide an obvious Close action. There is no Save or Cancel action because edits autosave immediately.

## Player hands

- Show the current `ITEM-001-player-selector` at the top.
- Each player colour owns a separate hand.
- Changing player immediately displays that player's stored hand.
- A player with no assigned hand displays an empty selected-card area ready for entry.
- Hands must be part of serializable board/game state, remain available after closing and reopening the sheet, and follow the application's board persistence boundary.
- Changing a hand must make dependent Plan Browser values refresh from the latest stored hand rather than stale state.

## Card editing

- Reuse the card presentation and resource order from the Cards section of SCR-004 and `ITEM-002-cards`.
- Tapping Brick, Wood, Hay, Sheep, or Ore adds one copy to the selected player's hand and autosaves it immediately.
- Copies of one resource appear as a staggered selected-card stack.
- Tapping a selected stack removes exactly one card of that resource and autosaves immediately.
- Removing the final card removes that stack and returns the resource count to zero.
- Provide a Clear action that removes every card from the selected player's hand immediately.
- Editing one player's hand must not mutate any other player's hand.
