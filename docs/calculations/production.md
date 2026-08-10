# Detailed production table

Suggested backend: make a table for each player:

| Player | Building ID | Building type | Adjacent type | Adjacent number |
| ------ | ----------- | ------------- | ------------- | --------------- |
| Red    | 1           | Settlement    | Brick         | 8               |
| Red    | 1           | Settlement    | Grain         | 5               |
| Red    | 1           | Settlement    | Lumber        | 2               |
| Red    | 3           | City          | Lumber        | 2               |
| Red    | 3           | City          | Ore           | 10              |
| Red    | 3           | City          | Wool          | 9               |



...

This has one row for each building (settlement or city)/adjacent hex pair. Building ID is unique to each placed building, and each should be adjacent to at most 3 hexes (so have 3 rows here). The adjacent number is the number on the hex.

## Cards per round

To calculate Brick production breakdown for Red player, we produce a new table, with the numbers 2–12. For each we give the total rows with Brick for Red (counting times 2 if the building type is a City). We have the probability of that number being rolled from the pips values in `SCR-001-board.md -> Number editing` (probability is pips divided by 36).

We then have a table like this for example:

| Player | Resource | Dice total | Probability | Production |
| ------ | -------- | ---------- | ----------- | ---------- |
| Red    | Brick    | 2          | 1/36        | 1          |
| Red    | Brick    | 3          | 2/36        | 0          |
| Red    | Brick    | 4          | 3/36        | 0          |
| Red    | Brick    | 5          | 4/36        | 2          |
| Red    | Brick    | 6          | 5/36        | 1          |
| Red    | Brick    | 7          | 6/36        | 0          |
| Red    | Brick    | 8          | 5/36        | 0          |
| Red    | Brick    | 9          | 4/36        | 0          |
| Red    | Brick    | 10         | 3/36        | 0          |
| Red    | Brick    | 11         | 2/36        | 0          |

Note that the `Production` for `Dice total` = 7 will always be zero.

From this the probability of getting `N` cards in a turn can be found as the sum of the probability column in rows where `Production = N`.

One round consists of all active players taking a turn. We must sum up all combinations to get the round probabilities. The probabilities of `N` cards in a turn should be precomputed. The combinatorial combinations to make each number of cards in a round for each number of players 2–6 should be hardcoded to save time.

For example:
`p(3 cards in a round) = p(0 in a turn) * p(0 in a turn) * p(1 in a turn) + p(0 in a turn) * p(1 in a turn) * p(0 in a turn) + p(1 in a turn) * p(0 in a turn) * p(0 in a turn)`

The mean production in a round should be equal to the probability column times the production column times the number of players. As a check, this should equal `0 * p(0) + 1 * p(1) + ...`.

`Rounds per card`

Using the calculation from above, we get `p(0 cards per round) = p0`.

Probability of 1 turn until a production is `1 - p0`.
Probability of 2 turns until a production is `p0 * (1 - p0)`.
Probability of 3 turns until a production is `p0**2 * (1 - p0)`.
etc


# Dice reliance

## Cards produced on dice result

This uses the backend table calculated above (i.e. the second, derivative table). We simply get the `Dice total` column against the `Production` column.

## Expected card production

Here, we simply multiply the above by the `Probability` column.
