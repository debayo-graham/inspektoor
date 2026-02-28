Project: Inspektoor Mobile App

Inspektoor is a commercial SaaS asset inspection application built with Flutter
and backed by Supabase.

We are reverse-engineering the workflow and feature set of an existing market
product called "Whip Around", but this is an original implementation.
No code, structure, or data model from that product exists here.

The reference product is used only to understand business workflows and user
expectations. All technical decisions must be based solely on this repository.

--------------------------------------------------
Target Product Capabilities (NOT assumed implemented)
--------------------------------------------------

The intended system will support:

- Vehicle / asset inspections
- Guided inspection checklists
- Photo capture and attachment
- Defect reporting and tracking
- Compliance visibility
- Offline-first field workflow with later synchronization
- Secure synchronization with Supabase backend

--------------------------------------------------
MVP Scope (What We Are Building Toward)
--------------------------------------------------

- Assets (vehicles and equipment)
- Asset profiles and history
- Defect management
- Inspection compliance tracking
- Customizable inspection forms and templates
- Maintenance scheduling
- People management:
  - Users
  - Driver profiles
  - Technician profiles
  - Custom roles and permissions
- Dashboard and reporting
- Reminders and notifications

These items describe the desired outcome, not the current implementation.
Discovery must determine what already exists versus what is incomplete.

--------------------------------------------------
AI Operating Purpose
--------------------------------------------------

This folder stores AI-generated understanding of the current codebase so that
analysis is not repeated across sessions.

All conclusions must come from THIS repository through inspection of the code.
Do not assume features exist unless they are verified in the source.
Do not redesign architecture. Document and extend what exists.