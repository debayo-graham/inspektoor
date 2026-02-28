# Database Change Workflow (Supabase)

## Human-Approved Execution Model

This document defines how database changes are handled for Inspektoor.

AI tools (including Claude Code) may assist in preparing migrations, but
they are NEVER allowed to apply them.

All production database changes require manual human review and
execution.

------------------------------------------------------------------------

## Location

This file should live at:

inspektoor_backend/DB_WORKFLOW.md

------------------------------------------------------------------------

## Critical Rule

Claude MUST NEVER execute:

-   supabase db push
-   supabase migration repair
-   supabase db reset
-   Any command that changes the remote database

Claude may only PREPARE migrations and commands. A human must manually
run them.

------------------------------------------------------------------------

## Allowed Responsibilities for Claude

Claude MAY:

1.  Create a migration file: supabase migration new
    `<descriptive_name>`{=html}

2.  Write SQL inside the migration.

3.  Generate a review script:
    inspektoor_backend/run_pending_migration.sh

Claude must STOP there.

------------------------------------------------------------------------

## Migration Naming Rules

Use clear, lowercase, underscore-separated names:

supabase migration new add_trial_expiration_column supabase migration
new create_inspection_reports_table

The filename is the intent. Do not reinterpret it.

------------------------------------------------------------------------

## Commit Message Rules

Commit messages must come directly from the migration filename.

Example:

20260301121000_add_trial_expiration_column.sql\
→ DB: add trial expiration column

Rules:

1.  Remove timestamp
2.  Replace underscores with spaces
3.  Prefix with "DB:"
4.  Do not summarize or reword

------------------------------------------------------------------------

## Script That Claude May Generate (But NOT Run)

inspektoor_backend/run_pending_migration.sh

Example contents:

#!/bin/bash \# REVIEW BEFORE RUNNING

cd "\$(dirname"\$0")"

echo "Applying migration..." supabase db push echo "Done."

Human must inspect and run this manually.

------------------------------------------------------------------------

## Human Review Process

1.  Review SQL
2.  Confirm change is safe
3.  Run script manually
4.  Commit and push manually

------------------------------------------------------------------------

## Philosophy

AI prepares. Humans approve. No automatic schema changes.
