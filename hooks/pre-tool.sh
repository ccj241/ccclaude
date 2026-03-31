#!/usr/bin/env bash
# ==============================================================================
# CCClaude PreToolUse Hook — Guardrail enforcement
# ==============================================================================
# Reads a JSON event from stdin and checks against safety rules.
# Returns a JSON permission decision: deny, allow, or ask.
#
# Rules enforced:
#   R01: Block sudo
#   R02: Block writes to protected paths
#   R03: Block shell redirects to protected paths
#   R04: Block git push --force and variants
#   R05: Block rm -rf on root/home (ask)
#   R06: Block --no-verify, --no-gpg-sign git flags
#   R07: Block git reset --hard on main/master
# ==============================================================================

set -euo pipefail

# --- Helpers ---

deny() {
  local reason="$1"
  cat <<EOF
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"$reason"}}
EOF
  exit 0
}

ask() {
  local reason="$1"
  cat <<EOF
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"$reason"}}
EOF
  exit 0
}

allow() {
  cat <<EOF
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"Passed all guardrail checks"}}
EOF
  exit 0
}

# --- Read and parse stdin ---

INPUT=$(cat)

# Extract tool name and input fields using jq.
# If jq is not available, allow by default to avoid blocking the user.
if ! command -v jq &>/dev/null; then
  allow
fi

TOOL_NAME=$(echo "$INPUT" | jq -r '.toolName // empty' 2>/dev/null)
TOOL_INPUT=$(echo "$INPUT" | jq -r '.toolInput // empty' 2>/dev/null)

# Only inspect Bash and Edit/Write tools
case "$TOOL_NAME" in
  Bash)
    COMMAND=$(echo "$INPUT" | jq -r '.toolInput.command // empty' 2>/dev/null)
    ;;
  Edit|Write)
    FILE_PATH=$(echo "$INPUT" | jq -r '.toolInput.file_path // empty' 2>/dev/null)
    ;;
  *)
    allow
    ;;
esac

# --- Rule checks for Bash commands ---

if [ "$TOOL_NAME" = "Bash" ] && [ -n "${COMMAND:-}" ]; then

  # R01: Block sudo
  # Matches sudo at the start of the command or after a pipe/semicolon/&&/||
  if echo "$COMMAND" | grep -qE '(^|[;&|]\s*)sudo\b'; then
    deny "[R01] sudo is blocked. Run commands without elevated privileges."
  fi

  # R04: Block git push --force and variants
  # Catches: --force, -f (when used with push), --force-with-lease to protected branches
  if echo "$COMMAND" | grep -qE 'git\s+push\b'; then
    if echo "$COMMAND" | grep -qE '\s(--force|-f|--force-with-lease)\b'; then
      deny "[R04] Force push is blocked. Use regular git push or rebase instead."
    fi
  fi

  # R06: Block --no-verify and --no-gpg-sign git flags
  # These flags bypass important safety checks
  if echo "$COMMAND" | grep -qE 'git\b.*--no-verify'; then
    deny "[R06] --no-verify is blocked. Git hooks must not be bypassed."
  fi
  if echo "$COMMAND" | grep -qE 'git\b.*--no-gpg-sign'; then
    deny "[R06] --no-gpg-sign is blocked. GPG signing must not be bypassed."
  fi

  # R07: Block git reset --hard on main/master
  # Prevents destructive history rewriting on protected branches
  if echo "$COMMAND" | grep -qE 'git\s+reset\s+--hard'; then
    # Check if we are targeting main or master
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")
    if echo "$COMMAND" | grep -qE '\b(main|master)\b' || \
       [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
      deny "[R07] git reset --hard on main/master is blocked. Use git revert instead."
    fi
  fi

  # R05: Block rm -rf on project root or home directory
  # Uses "ask" instead of "deny" so the user can override if intentional
  if echo "$COMMAND" | grep -qE 'rm\s+(-[a-zA-Z]*r[a-zA-Z]*f|--recursive)\b'; then
    # Check for dangerous target paths: /, ~, $HOME, ., ..
    if echo "$COMMAND" | grep -qE 'rm\s+(-[a-zA-Z]*rf?[a-zA-Z]*)\s+(/\s*$|~/|\.\.?\s*$|\$HOME)'; then
      ask "[R05] rm -rf targeting root or home directory detected. Are you sure?"
    fi
    # Also check for the current project root (. or ./)
    if echo "$COMMAND" | grep -qE 'rm\s+(-[a-zA-Z]*rf?[a-zA-Z]*)\s+\.\/?$'; then
      ask "[R05] rm -rf targeting current directory detected. Are you sure?"
    fi
  fi

  # R02 & R03: Block writes/redirects to protected paths
  # Protected: .git/, .env, ~/.ssh/, ~/.aws/, ~/.gnupg/
  PROTECTED_PATHS=('.git/' '.env' '~/.ssh/' '~/.aws/' '~/.gnupg/' '$HOME/.ssh/' '$HOME/.aws/' '$HOME/.gnupg/')
  for pp in "${PROTECTED_PATHS[@]}"; do
    # R03: Check for shell redirects (>, >>, tee) targeting protected paths
    if echo "$COMMAND" | grep -qF "$pp"; then
      if echo "$COMMAND" | grep -qE '(>|>>|tee\s)'; then
        deny "[R03] Shell redirect to protected path '$pp' is blocked."
      fi
    fi
  done
fi

# --- Rule checks for Edit/Write tools ---

if [ "$TOOL_NAME" = "Edit" ] || [ "$TOOL_NAME" = "Write" ]; then
  FILE_PATH=${FILE_PATH:-}
  if [ -n "$FILE_PATH" ]; then

    # R02: Block writes to protected paths
    # Check each protected path pattern
    case "$FILE_PATH" in
      */.git/*)
        deny "[R02] Writing to .git/ directory is blocked."
        ;;
      */.env|*/.env.*)
        deny "[R02] Writing to .env files is blocked. Use environment variables instead."
        ;;
    esac

    # Expand ~ for home directory checks
    EXPANDED_HOME="${HOME:-/home/$USER}"
    case "$FILE_PATH" in
      "$EXPANDED_HOME/.ssh/"*|"~/.ssh/"*)
        deny "[R02] Writing to ~/.ssh/ is blocked."
        ;;
      "$EXPANDED_HOME/.aws/"*|"~/.aws/"*)
        deny "[R02] Writing to ~/.aws/ is blocked."
        ;;
      "$EXPANDED_HOME/.gnupg/"*|"~/.gnupg/"*)
        deny "[R02] Writing to ~/.gnupg/ is blocked."
        ;;
    esac
  fi
fi

# --- All checks passed ---
allow
