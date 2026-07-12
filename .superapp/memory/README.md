# Superapp Project Memory

This directory contains persistent memory for the Superapp coding agent.

Rules:

- Source code, project configuration, git state, and build output are the source of truth.
- Memory may be outdated; verify against files before acting.
- Keep entries concise, dated when relevant, and connected to file paths.
- Prefer updating existing entries over duplicating notes.
- Do not store secrets, credentials, raw logs, generic implementation notes, or temporary scratch details.

Files:

- `project.md`: stable app facts, stack, style, and important paths.
- `task-state.md`: current work-in-progress, open issues, and next likely step.
- `decisions.md`: durable technical and product decisions.
- `artifacts.md`: important generated features and file clusters.
- `pitfalls.md`: known sharp edges, failed attempts, and recurring build issues.
