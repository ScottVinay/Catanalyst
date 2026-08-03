# SCR-002 – Plan Browser

## Purpose

The Plan Browser provides statistical predictions for the time required to complete various build plans. It is accessed from the universal navigation bar and allows the user to browse both predefined ("Default") plans and user-defined ("Custom") plans.

---

# Entry and Navigation

### Access

* The Plan Browser shall be opened by tapping the **Plans** icon in the universal navigation bar.
* The universal navigation bar shall be visible across all application screens.
* The Plan Browser shall animate into view by sliding upward from the bottom of the screen.

### Exit

* Closing behaviour is defined by the application's standard bottom-sheet navigation behaviour.

---

# Layout

The screen shall contain:

1. A tab selector at the top with:

   * **Default**
   * **Custom**

2. A plan browser table occupying the main body of the screen.

3. A graph navigation button in the upper-right corner.

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
9. Development Card

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
* Development Card

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

Selecting this row shall initiate creation of a new custom plan.

## Editing

Holding on a row in custom brings up `SCR-004-edit.md`.
Holding on a row in default briefly shows a message saying "Default plans cannot be edited.".


---



# Connection to backend

If the backend has not yet been built to run simulations and provide these values, show appropriate placeholder values. However, these should be in red to indicate they are placeholders.
