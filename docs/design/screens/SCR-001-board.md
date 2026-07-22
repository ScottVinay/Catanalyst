# Purpose

This is the main screen for viewing and editing the current Catan board.

There is an edit button, which changes the toolbars, and takes us into edit mode.

# Layout

- Board centred on screen
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

# Editing

When edit mode is active:

## Hexes

There should be a toggle switch in the top right determining if we are editing terrain types or numbers.

### Terrain type editing

Tapping a hex opens the terrain selector. This is a set of 7 coloured circles surrounding the hex.
By tapping one of these circles, it applies the chosen terrain type to the hex. If we tap the hex again without making a choice, then it closes the radial.

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

If multiple players are enabled, a selector at the top of the screen determines which player we are editing for.

## Vertices

Tapping a vertex adds or upgrades settlements and cities.

If multiple players are enabled, a selector at the top of the screen determines which player we are editing for.

## Completing

There should be a "Done" button at the bottom to save the board and exit edit mode.

