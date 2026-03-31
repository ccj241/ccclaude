#!/bin/bash
# CCClaude Project Initializer
# Usage: /path/to/CCClaude/init.sh [project-dir]
#
# Sets up CCClaude harness in a target project by creating the directory
# structure and symlinking shared resources.

set -euo pipefail

PROJECT_DIR="${1:-.}"
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
HARNESS_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "CCClaude Initializer"
echo "===================="
echo "Harness:  $HARNESS_DIR"
echo "Project:  $PROJECT_DIR"
echo ""

# Verify harness directory
if [ ! -f "$HARNESS_DIR/CLAUDE.md" ]; then
    echo "Error: Cannot find CCClaude harness at $HARNESS_DIR"
    exit 1
fi

# Step 1: Create .claude directory structure
echo "[1/5] Creating directory structure..."
mkdir -p "$PROJECT_DIR/.claude/commands"
mkdir -p "$PROJECT_DIR/rules/common"
mkdir -p "$PROJECT_DIR/rules/_project"
mkdir -p "$PROJECT_DIR/skills/common"
mkdir -p "$PROJECT_DIR/skills/_project"
mkdir -p "$PROJECT_DIR/profiles/common"
mkdir -p "$PROJECT_DIR/profiles/_project"

# Step 2: Symlink shared rules
echo "[2/5] Linking shared rules..."
for rule_file in "$HARNESS_DIR/rules/common/"*.md; do
    if [ -f "$rule_file" ]; then
        basename="$(basename "$rule_file")"
        target="$PROJECT_DIR/rules/common/$basename"
        if [ ! -e "$target" ]; then
            ln -sf "$rule_file" "$target"
            echo "  Linked: rules/common/$basename"
        else
            echo "  Exists: rules/common/$basename (skipped)"
        fi
    fi
done

# Step 3: Symlink shared skills
echo "[3/5] Linking shared skills..."
for skill_dir in "$HARNESS_DIR/skills/common/"*/; do
    if [ -d "$skill_dir" ]; then
        dirname="$(basename "$skill_dir")"
        target="$PROJECT_DIR/skills/common/$dirname"
        if [ ! -e "$target" ]; then
            ln -sf "$skill_dir" "$target"
            echo "  Linked: skills/common/$dirname"
        else
            echo "  Exists: skills/common/$dirname (skipped)"
        fi
    fi
done

# Step 4: Symlink shared profiles
echo "[4/5] Linking shared profiles..."
for profile_file in "$HARNESS_DIR/profiles/common/"*; do
    if [ -f "$profile_file" ]; then
        basename="$(basename "$profile_file")"
        target="$PROJECT_DIR/profiles/common/$basename"
        if [ ! -e "$target" ]; then
            ln -sf "$profile_file" "$target"
            echo "  Linked: profiles/common/$basename"
        else
            echo "  Exists: profiles/common/$basename (skipped)"
        fi
    fi
done

# Step 5: Generate CLAUDE.md from template if it does not exist
echo "[5/5] Setting up CLAUDE.md..."
if [ ! -f "$PROJECT_DIR/CLAUDE.md" ]; then
    PROJECT_NAME="$(basename "$PROJECT_DIR")"
    sed "s/{Project Name}/$PROJECT_NAME/g" "$HARNESS_DIR/templates/CLAUDE.md.template" \
        > "$PROJECT_DIR/CLAUDE.md"
    echo "  Created: CLAUDE.md (from template)"
else
    echo "  Exists: CLAUDE.md (skipped)"
fi

# Create .gitkeep files in _project directories
touch "$PROJECT_DIR/rules/_project/.gitkeep"
touch "$PROJECT_DIR/skills/_project/.gitkeep"
touch "$PROJECT_DIR/profiles/_project/.gitkeep"

echo ""
echo "CCClaude initialized successfully."
echo ""
echo "Next steps:"
echo "  1. Edit CLAUDE.md to describe your project"
echo "  2. Add project-specific rules in rules/_project/"
echo "  3. Add project-specific skills in skills/_project/"
echo "  4. Start with: /plan <your feature description>"
