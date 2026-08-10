# SCR-002 – Analysis

## Purpose and entry

Analysis presents production and ordered-plan completion estimates. It opens as the existing large bottom sheet from the Board's **Analysis** button and closes with Close.

Production/Plans uses the full available content width. ITEM-001 sits on the row beneath it, with Help independently aligned at the far right of that row. Help presents contextual Analysis guidance. Analysis does not show a Graph action.

## Tabs and player selection

The selector has **Production** and **Plans** tabs. Each tab places ITEM-001 beneath it and offers all six owners plus the sliced All-player choice. All shows every matching custom item with a triangular owner-colour marker filling the upper-right corner of its fixed cell. Each triangle has a contrasting line along its hypotenuse so white ownership remains visible on light rows. Individual-player views omit ownership markers. Creation from All starts with Red; editors offer only individual owners.

# Production

The Production tab has multiple discrete elements, each element showing a different table, graph, or other analysis. These should be distinct UI elements, to allow for easy extension in the future to new graphs.

See `production_mock.jpg` for a visualisation of `Detailed production table`, `Radial production plot`, and `Dice number reliance`.

## Element: Detailed production table

Element title: "Detailed production analysis"

This table has a toggle in the upper-left (not shown in `production_mock.jpg`). This toggle has `Cards per round` on the left, and `Rounds per card` on the right. There is a question mark next to this. Tapping the question mark shows the following tip text:

"""
`Cards per round` shows the mean average of how many of each card you typically get on one round (i.e. from your turn back round to your turn again).

`Rounds per card` shows how many round you typically need to wait until you get at least one of the given card. This does not account for trades, robber, or held cards.

Tap any resource to see a detailed breakdown of this average.
"""

Production follows the same native table styling and density as Plans. The Production/Plans picker remains fixed at the top. The resource-and-icon column is fixed, only player values scroll horizontally, and the active metric header spans only the values viewport. Resource icons are shown for every row. Player headings use their player colour except White, which uses grey for contrast on the system background.

Do not allow scrolling past the limit and snapping back, stop at the scroll limit both horizontally and vertically. The rows should be always attached to their corresponding index columns.

Tapping a row should reveal sub-rows. These should be left-indented to show they are sub-rows, but the value columns should remain aligned.

In `Cards per round` mode, these columns should read:

- 0 cards
- 1 card
- 2 cards
- 3 cards
- 4+ cards

In `Rounds per card` mode, these columns should read:

- 1 round
- 2 rounds
- 3 rounds
- 4+ rounds

The icons for the resources should be coloured:

- All: purple
- Brick: red
- Lumber: tree with green leaves and brown trunk
- Ore: grey/blue
- Grain: yellow
- Wool: white with black outline

See `docs/calculations/production.md` for precise instructions on how to calculate these values.

## Element: Radial production plot

Element title: "Production balance"

This is a radial plot, showing, in order going clockwise from the top, Brick, Lumber, Ore, Grain, Wool. There is a player picker that allows any number of the active players to be selected by ticking their colours. A polygon is shown for each selected player. The radial distance of each vertex is the value of that `Cards per round` that that player has on that resource, as calculated in `Detailed production table`. These are normalised by the maximum value seen across all player/resource pairs. So the furthest vertex is always at the same radial distance, but a player with less overall production will still have a smaller polygon.

## Element: Dice reliance

Element title: "Dice reliance"

In the top-left there is a drop-down selector box that allows for the selecting of exactly one of the active players.

Beneath this there is a toggle with two options (not shown in the mockup).

Left option is `Cards produced on dice result`
Right option is `Expected card production`

To the right of this there is a question mark. Tapping this reveals the following tip text:

"""
`Cards produced on dice result` shows how many cards you will get upon getting a given dice result.

`Expected card production` shows this value multiplied by the probability of that number being rolled to show the expected contribution of each number towards your total production.
"""

The main content of this element is a full-width bar chart. Numbers 2–12 (not including 7) are shown on the x-axis, with the label "Dice result". The y-axis is labelled with numbers, with the label "Production". Appropriate horizontal rules are shown.

See `docs/calculations/production.md` for precise instructions on how to calculate these values.

# Plans

Plans contains matching player-owned ordered construction plans followed by **New plan**. New plan opens SCR-004's construction editor directly and defaults to `Plan N` and the hammer icon.

Holding a plan opens SCR-004 directly. Tapping expands/collapses it. Production/Card stats after plan completion appear first, followed by ordered Steps.

Expanded group labels and icon-only subrows reserve a 12-point blank block at the left edge of the fixed column, visibly nesting them under their parent. Step order is preserved. Card rows are Brick, Wood, Hay, Sheep, Ore.

## Icons and ownership

Custom rows show their saved icon and name. In All-player mode they also show the saved owner's corner triangle. Built-in rows retain their fixed icons. Custom icon selection is specified by SCR-004.
