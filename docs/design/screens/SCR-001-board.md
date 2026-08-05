# Purpose

This is the main screen for viewing and editing the current Catan board.

There is an edit button, which changes the toolbars, and takes us into edit mode.

# Layout

- Board centred on screen
- In Overview zoom, bias the board slightly upward so it is visually centred within the complete screen layout.
- Toolbar on bottom:
    - Button: Edit
    - Button: View plans panel
    - Button: Player summary panel

# Zoom

Two zoom levels are supported:

- Overview
- Detail

Users may switch between them.

The board does not support continuous pinch zoom.

Detail shall use a higher fixed scale than the current implementation. While panning in Detail, the board may continue behind fixed controls such as Done, the edit selector, help, and player selection. Those controls remain visually above the board and do not move with it.

# Editing

When edit mode is active:

## Hexes

There should be a toggle switch in the top right determining if we are editing terrain types or numbers.

### Terrain type editing

Holding a hex opens the terrain selector. This is a set of 7 coloured circles surrounding the hex.
By moving while holding to one of these circles, that circle will be highlighted. Releasing applies the chosen terrain type to the hex. If we release the hex again while in the centre making a choice, then it closes the radial without applying.

If we are in zoomed-in mode, then tapping a hex centres the view on that hex.

The circles represent:

- Brick
- Ore
- Wheat
- Lumber
- Wool
- Desert
- Ocean

There should be simple icons on the hex and corresponding colour in the radial selector that refer to the terrain type.

Applied terrain shall also be represented by several copies of the corresponding terrain symbol distributed over each hex. These symbols render at approximately 50% opacity behind the number token.

### Number editing

If number editing is selected, a similar wheel should appear showing the numbers 2 – 12, but not including 7. Whichever number is selected should appear in the middle of the hex in a beige circle. Should also include the option to remove the number entirely.

Underneath the number and within the circle should be a number of dots depending on the number.

| Number | Dots |
| ------ | ---- |
| 2      | 1    |
| 3      | 2    |
| 4      | 3    |
| 5      | 4    |
| 6      | 5    |
| 8      | 5    |
| 9      | 4    |
| 10     | 3    |
| 11     | 2    |

If 6 or 8 are selected, then the number and the dots should be coloured red. Otherwise, black.

## Roads

Tapping an edge toggles a road.

Roads always render behind settlements and cities wherever their visuals overlap.

If multiple players are enabled, a selector at the top of the screen determines which player we are editing for.

## Vertices

Tapping a vertex adds or upgrades settlements and cities.

If multiple players are enabled, a selector at the top of the screen determines which player we are editing for.

## Completing

There should be a "Done" button at the bottom to save the board and exit edit mode.

## Player selection

ITEM-001-player-selector should be visible and active.
