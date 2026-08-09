# herdr-handy

## Issue tracker

GitHub Issues are canonical and pull requests are excluded from the request surface. See `.agents/issue-tracker.md`.

## Triage labels

The default five-role vocabulary is configured. See `.agents/triage-labels.md`.

## Domain docs

This repository uses the single-context layout. See `.agents/domain.md`.

## Structural codebase work

Use `codebase-memory` when a task requires discovering relevant code or understanding relationships across files or symbols. For work confined to one already-known file, inspect the source directly.

When it applies, establish the structural picture from the graph before broad source exploration.

- Follow the skill's freshness and evidence workflow.
- Use graph findings to select files and symbols for targeted source inspection; use text search to verify findings and cover graph gaps.
- Before proposing or making structural changes, read `.agents/CONTEXT.md` and relevant ADRs.
- Treat structural conclusions as complete only when material graph findings are verified against source and any freshness or coverage limits are stated.

Read @AGENTS.md
