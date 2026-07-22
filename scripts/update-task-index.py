#!/usr/bin/env python3
"""Update docs/tasks/INDEX.md from the task files."""

from pathlib import Path


tasks_dir = Path(__file__).resolve().parents[1] / "docs" / "tasks"
tasks = sorted(tasks_dir.glob("TASK-*.md"))
lines = ["# Task Index", ""]
for task in tasks:
    title = task.read_text(encoding="utf-8").splitlines()[0].removeprefix("# ")
    lines.append(f"- [{title}]({task.name})")
tasks_dir.joinpath("INDEX.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
