# SCR-002 – Analysis

## Purpose and entry

Analysis presents production and ordered-plan completion estimates. It opens as the existing large bottom sheet from the Board's **Analysis** button and closes with Close.

Production/Plans uses the full available content width. ITEM-001 sits on the row beneath it, with Help independently aligned at the far right of that row. Help presents contextual Analysis guidance. Analysis does not show a Graph action.

## Tabs and player selection

The selector has **Production** and **Plans** tabs. Each tab places ITEM-001 beneath it and offers all six owners plus the sliced All-player choice. All shows every matching custom item with a triangular owner-colour marker filling the upper-right corner of its fixed cell. Each triangle has a contrasting line along its hypotenuse so white ownership remains visible on light rows. Individual-player views omit ownership markers. Creation from All starts with Red; editors offer only individual owners.

## Shared table

Both tabs use the same fixed-column table and REQ-008 scrolling behavior. The initial summary section contains Mean, Median, 25th, and 75th under “Turns until acquired/built”. The probability section contains cumulative T1–T10 percentages under “Probability within N turns”. Placeholder results are red.

All data rows use a compact 36-point height. Fixed labels and scrolling values always insert, remove, and scroll matching heights.

## Production

Production contains, in order, the fixed Ore, Brick, Wheat, Sheep, Wood, Road, Settlement, City, and Dev Card checks; then matching player-owned custom production checks; then **New production check**.

Built-in checks cannot be edited. Holding one briefly explains this. Holding a custom production check opens SCR-004 directly. Tapping a custom check expands/collapses its Card stats after completion section.

New production check opens SCR-004's production-check editor directly and defaults to `Prod N` and the cards icon.

## Plans

Plans contains matching player-owned ordered construction plans followed by **New plan**. New plan opens SCR-004's construction editor directly and defaults to `Plan N` and the hammer icon.

Holding a plan opens SCR-004 directly. Tapping expands/collapses it. Production/Card stats after plan completion appear first, followed by ordered Steps.

Expanded group labels and icon-only subrows reserve a 12-point blank block at the left edge of the fixed column, visibly nesting them under their parent. Step order is preserved. Card rows are Brick, Wood, Hay, Sheep, Ore.

## Icons and ownership

Custom rows show their saved icon and name. In All-player mode they also show the saved owner's corner triangle. Built-in rows retain their fixed icons. Custom icon selection is specified by SCR-004.
