---
name: harden
description: "Audit and harden role/profile/rule definitions — inject precise bans"
---

# Harden

Load and execute the Harden role from `roles/harden.md`.

## Target

$ARGUMENTS

Pass `$ARGUMENTS` as the audit target to the Harden role.

If no argument provided, ask the user which role, profile, or rule file to audit.
If argument is `all`, audit all role and command files sequentially.
