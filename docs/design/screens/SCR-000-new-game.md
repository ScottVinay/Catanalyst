# SCR-000 – New game

## Purpose

This is screen 0: the entry screen for starting a game. It reuses the existing board-size selection screen shown before the first Board is created.

## Entry

- On the Board, a burger-menu button appears in the upper-left corner.
- The menu initially contains one action: **New game**.
- Choosing **New game** returns to this screen.

## Layout

- Retain the existing Catanalyst title, hexagon symbol, **Create a board** heading, and board-size helper text.
- Show the existing three board-size choices.
- **Standard board** is enabled and creates a fresh standard game.
- **Large board** and **Custom board** remain visible but disabled/greyed out.

## State boundary

- The active game's Board, hands, Analysis items, player ownership, and view orientation persist across app termination until the user starts a fresh game.
- Creating a new Standard board replaces the active game with a clean game state and opens SCR-001-board.
- Returning to this screen must not accidentally carry Board or Analysis state into the newly created game.
