# SCR-002 – Plan Browser

## Purpose

The Plan Browser provides statistical predictions for the time required to complete various build plans. It is accessed from the universal navigation bar and allows the user to browse both predefined ("Default") plans and user-defined ("Custom") plans.

---

# Entry and Navigation

## Access

* The Plan Browser shall be opened by tapping the **Plans** icon in the universal navigation bar.
* The universal navigation bar shall be visible across all application screens.
* The Plan Browser shall animate into view by sliding upward from the bottom of the screen.

## Exit

* Closing behaviour is defined by the application's standard bottom-sheet navigation behaviour.

---

# Layout

The screen shall contain:

1. A tab selector at the top with:

   * **Default**
   * **Custom**

2. A plan browser table occupying the main body of the screen. See `REQ-008-scroll`

3. A graph navigation button in the upper-right corner.
4. A question-mark help button beside the graph button.

The graph and question-mark buttons shall be separate controls with independent, non-overlapping tap and pressed/highlight states. Tapping either control must not animate, bounce, highlight, or activate the other control.

The table layout shall be identical in both tabs unless otherwise specified.

---

# Default Plans

The Default tab shall contain the following predefined plans:

1. Ore
2. Brick
3. Wheat
4. Sheep
5. Wood
6. Road
7. Settlement
8. City
9. Dev Card

The contents of the Default tab are fixed.

Users shall not be able to create, edit, delete, or reorder default plans.

---

# Plan Table

Each plan shall occupy a single row.

Each row shall contain the following columns, in order.

## Item Icon

Displays an icon representing the plan.

Examples include:

* Ore
* Brick
* Wheat
* Sheep
* Wood
* Road
* Settlement
* City
* Dev Card

---

## Mean

Displays the predicted mean number of turns until the selected player completes the plan.

---

## Median

Displays the predicted median number of turns until completion.

---

## 25th Percentile

Displays the predicted 25th percentile completion time.

---

## 75th Percentile

Displays the predicted 75th percentile completion time.

---

## Probability Columns

Following the summary statistics shall be ten probability columns.

Each column displays the probability that the selected player completes the plan exactly within the specified number of turns.
Note, this means the probability that it is completed on turn N or less. i.e. p(5) is completed on turns 5, 4, 3, 2, 1.

The columns shall be:

* 1 turn
* 2 turns
* 3 turns
* 4 turns
* 5 turns
* 6 turns
* 7 turns
* 8 turns
* 9 turns
* 10 turns

Values shall be displayed as percentages.

---

# Selected Player

All displayed statistics shall correspond to the player currently selected elsewhere in the application.

Changing the selected player shall update all displayed statistics.

---

# Graph Navigation

An icon representing a graph shall be displayed in the upper-right corner of the screen.

Selecting this icon shall navigate to:

* `SCR-003-graphs.md`

Its tap target shall be independent from the adjacent Plan Browser help button.

---

# Custom Plans

The Custom tab shall use the same table layout and statistical columns as the Default tab.

Unlike the Default tab:

* Users may create new plans.
* User-created plans shall be displayed in the table.

Creation, editing, and deletion behaviour is specified elsewhere.

---

## New Plan Row

A dedicated row shall be displayed for creating new plans.

If one or more custom plans exist:

* The **New Plan** row shall appear immediately below the final custom plan.

If no custom plans exist:

* The **New Plan** row shall appear at the top of the table.

The row shall contain:

* A "+" icon.
* The label **New Plan**.

Selecting this row shall initiate creation of a new custom plan and go directly to `SCR-004-edit.md`.

## Editing

Holding on a row in custom brings up `SCR-004-edit.md` directly.
Holding on a row in default briefly shows a message saying "Default plans cannot be edited.".

Tapping on a row in custom expands the row, giving two sets of subrows This means we create one or more sub rows beneath the plan's row.

Tapping the main row again closes it.

The sub rows should move smoothly out from the main row. Any other plan rows beneath this should move down smoothly too.

Construction-step subrows, when present, shall appear first in their plan order. Card-stat subrows shall follow them.

### Subrows: Intermediary steps in the plan

Each sub-row corresponds to an action that is part of that plan, either building a road, settlement, or city. These are labelled with icons only. Use the same columns, we see the probabilities and number of turns required to reach these intermediatry levels in the plan.

There is a label on the left, clearly showing all of these rows, that says "Steps"

### Subrows: Cards

Here, there are subrows, one for each of the card types. Again these are just labelled by the icons. These again use the same columns. The label on the left indicating all of these says "Card stats after plan completion".

Every custom plan shall show the five card-stat rows when expanded. Construction plans additionally show their ordered intermediary-step rows before the card-stat section.

## All players

The Custom tab player selector shall include an additional sliced multicolour circle representing all players. Selecting it displays custom plans belonging to every player. Each custom plan row shows a small dot in its owner's colour beside the plan name.

New Plan remains available while All players is selected. The new plan editor does not offer the All option: it starts with Red selected and allows any individual player colour to be chosen using the normal player selector.


---



# Connection to backend

If the backend has not yet been built to run simulations and provide these values, show appropriate placeholder values. However, these should be in red to indicate they are placeholders.

# Super column headers

- Above columns that express numbers of turns (e.g. mean, median, 25th percentile, 75th percentile) there should be a meta-column header spanning those columns that says "Turns until acquired/built".
- Above columns that express probabilities of the things being built in a certain number of turns, there should be a meta-column header spanning those columns that says "Probability within N turns".
