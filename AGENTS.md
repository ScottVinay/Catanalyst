# Catan Planner agent instructions

## Project

This repository contains a native iPhone application for analysing
Catan board states and simulating ordered building plans.

Before substantial work, read:

- `PRODUCT.md`
- `REQUIREMENTS.md`
- `ARCHITECTURE.md`
- The most recent work  active task under `docs/tasks/`

## Document authority

- `PRODUCT.md` is human-owned.
- `REQUIREMENTS.md` is human-owned.
- `ROADMAP.md` is human-owned.
- Do not change product requirements unless explicitly instructed.
- When code conflicts with a requirement, report the conflict.
- Record newly discovered work as a proposed task rather than silently
  expanding the active task.

The agent may update:

- Source code
- Tests
- Add new tasks to `docs/tasks`.
    - These should begin `TASK-xxx` where `xxx` is a number.
    - These should include a status, from: `not-started`, `in-progress`, `review`.
    - These should include a reference of a requirement tag (`REQ-xxx` from `REQUIREMENTS.md`) that is addressed by this tag, if any.
    - These should include a priority of P0 (critical) to P4 (low).
    - You may edit previous tasks.
- Task status up to `review`.
- Task implementation notes.
- Task completion evidence.
- Add new decisions to `docs/decisions`.
    - These should begin `DEC-xxx` where `xxx` is a number.
    - These should include the reason that a decision has been made.
    - You may edit previous decisions.
- `ARCHITECTURE.md` after structural changes
- `docs/progress/CURRENT.md`

The agent must not mark a task `done`.

## Workflow

Before editing:

1. Read the active task and linked requirements.
2. Inspect the relevant source code and tests.
3. Produce a plan for non-trivial work.
4. Identify ambiguities, risks and requirement conflicts.
5. Do not edit files until the plan has been accepted.

During implementation:

1. Stay within the task scope.
2. Prefer small, reviewable changes.
3. Add tests for changed behaviour.
4. Do not delete or weaken tests merely to make them pass.
5. Do not add dependencies without explaining why.
6. Do not rewrite unrelated files.
7. Use deterministic random seeds in simulation tests.

Before finishing:

1. Run `./scripts/verify.sh`.
2. Review the complete diff.
3. Check every acceptance criterion.
4. Record tests and commands in the task file.
5. Record remaining risks and manual checks.
6. Update `docs/progress/CURRENT.md`.
7. Move the task to `review` if automated checks pass.

## Architecture

- Use Swift and SwiftUI.
- Keep domain and simulation logic independent of SwiftUI.
- UI views must not contain core probability calculations.
- Simulation runs must support deterministic seeds.
- Avoid global mutable state.
- Board states and plans must be serialisable.
- Separate simulation policy from state transitions.
- Prefer value types for immutable domain data.
- Avoid unnecessary allocation in Monte Carlo inner loops.

## Testing

Tests should cover:

- domain rules
- production calculations
- legal and illegal state transitions
- build costs
- port trades
- deterministic simulations
- analytically solvable probability cases
- regression fixtures

Monte Carlo tests should use tolerances rather than expect one exact
random result.

## Ready-for-review definition

Work is ready for review only when:

- the requested behaviour is implemented
- relevant tests have been added
- `./scripts/verify.sh` passes
- no unrelated changes are present
- task documentation has been updated
- any required manual testing has been described
