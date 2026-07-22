# Catanalyst

## Product summary

Catanalyst is an iPhone application that allows players to enter or
photograph a Catan board and analyse the current game state.

Its standout feature is a multi-stage planning simulator. A player can
enter their current buildings, roads, ports and held resource cards,
then define one or more ordered plans such as:

1. Build a road.
2. Build a settlement on a wool port.
3. Upgrade an existing settlement to a city.

The app simulates how long each plan is likely to take while accounting
for production changes caused by intermediate actions.

## Problem

Catan players often compare moves using simple pip totals. Pip totals do
not adequately capture:

- resource balance
- build-specific bottlenecks
- ports and trade ratios
- production variance
- changing production after new construction
- uncertainty in the time required to execute a sequence of moves
- the long-term difference between alternative plans

The application should turn the visible board state into practical,
understandable decision support.

## Target users

### Primary users

- Regular Catan players interested in improving their decisions
- Players reviewing completed games
- Groups that agree to use a shared analysis tool during play

### Secondary users

- Content creators analysing board positions
- Competitive players studying openings and game states
- New players learning how production and resource balance work

## Core value

The application should help answer:

- What does each player produce?
- Which resources are bottlenecks?
- What can I probably build in the next few rounds?
- How long will a particular sequence of moves take?
- Which of two plans is faster, safer or stronger?
- How does gaining a port, settlement or city alter future outcomes?

## Core product areas

1. Manual board creation
2. Player-state entry
3. Production analysis
4. Ordered plan construction
5. Multi-stage Monte Carlo simulation
6. Plan comparison

## Future areas

1. Post-game luck and decision analysis
2. Photo-assisted board recognition

## Product principles

### Explain uncertainty

Show distributions, percentiles and confidence rather than only averages.

### Avoid false precision

Separate exact board information from estimates based on hidden hands,
trades and opponent behaviour.

### Allow correction

Automatic board recognition must always support manual correction.

### Stay useful without recognition

The app must remain fully functional through manual board entry.

## Initial scope

The first release should support:

- manual board entry
- settlements, cities, roads and ports
- current player hand
- ordered road, settlement and city plans
- bank and port trading
- Monte Carlo completion-time distributions
- resource distributions at each plan milestone
- comparison of multiple plans

## Initial non-goals

The first release will not attempt to model:

- realistic domestic negotiation
- sophisticated opponent strategy
- every expansion or house rule
- perfectly automatic board recognition
- automatic generation of optimal plans
- competitive rankings or online multiplayer

## Success criteria

The first useful version succeeds when a user can:

1. Recreate a game state without excessive effort.
2. Construct two alternative plans (see `docs/design/planning.md` for more details on what plans are).
3. Simulate both plans.
4. Understand which plan is faster and why.
5. Inspect how intermediate buildings changed later production.

