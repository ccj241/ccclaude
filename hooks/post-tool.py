#!/usr/bin/env python3
"""
CCClaude PostToolUse Hook — Content scanner.

Reads a JSON event from stdin after a tool executes.
Scans written/edited file content for:
  - Hardcoded secrets (API keys, passwords, private keys)
  - Dangerous code patterns (eval, innerHTML, exec, etc.)
  - Debug remnants (console.log, print, debugger, bare TODO/FIXME)

Outputs JSON with findings list. Always exits 0 (warn, never block).
"""

import json
import os
import re
import sys

# ---------------------------------------------------------------------------
# Rule definitions (inline — mirrors rules.json patterns)
# ---------------------------------------------------------------------------

SECRET_PATTERNS = [
    (r"sk-[a-zA-Z0-9]{20,}", "OpenAI/Stripe secret key"),
    (r"pk-[a-zA-Z0-9]{20,}", "Stripe publishable key"),
    (r"AKIA[0-9A-Z]{16}", "AWS Access Key ID"),
    (r"ghp_[a-zA-Z0-9]{36}", "GitHub personal access token"),
    (r"npm_[a-zA-Z0-9]{36}", "npm access token"),
    (r"-----BEGIN (RSA |EC )?PRIVATE KEY-----", "Private key"),
    (r"password\s*[:=]\s*['\"][^'\"]{4,}['\"]", "Hardcoded password"),
    (r"secret\s*[:=]\s*['\"][^'\"]{4,}['\"]", "Hardcoded secret"),
    (r"api[_-]?key\s*[:=]\s*['\"][^'\"]{8,}['\"]", "Hardcoded API key"),
]

DANGEROUS_PATTERNS = [
    (r"\beval\s*\(", "eval() — arbitrary code execution risk"),
    (r"\.innerHTML\s*=", "innerHTML — XSS risk, use textContent or sanitize"),
    (r"dangerouslySetInnerHTML", "dangerouslySetInnerHTML — XSS risk in React"),
    (r"\bexec\s*\(", "exec() — arbitrary code execution risk"),
    (r"\b__import__\s*\(", "__import__() — dynamic import risk"),
    (r"subprocess.*shell\s*=\s*True", "subprocess with shell=True — command injection risk"),
    (r"os\.system\s*\(", "os.system() — use subprocess instead"),
    (r"pickle\.loads?\s*\(", "pickle.load() — unsafe deserialization"),
    (r"yaml\.load\s*\([^)]*\)(?!.*Loader)", "yaml.load() without safe Loader"),
]

# File extensions that are considered "non-test" for debug remnant detection
TEST_INDICATORS = ("test", "spec", "_test.", ".test.", "tests/", "spec/", "__tests__/")

DEBUG_PATTERNS = [
    (r"\bconsole\.(log|debug|info|warn|error)\s*\(", "console.log statement", (".js", ".ts", ".jsx", ".tsx", ".vue")),
    (r"^\s*print\s*\(", "print() statement", (".py",)),
    (r"\bdebugger\b", "debugger statement", (".js", ".ts", ".jsx", ".tsx", ".vue")),
    (r"\bpdb\.set_trace\s*\(", "pdb breakpoint", (".py",)),
    (r"\bbreakpoint\s*\(", "Python breakpoint()", (".py",)),
    (r"\b(TODO|FIXME|HACK|XXX)\b(?!.*\b[A-Z]+-\d+)", "TODO/FIXME without ticket reference", None),
]


# ---------------------------------------------------------------------------
# Scanner
# ---------------------------------------------------------------------------

def scan_content(content: str, file_path: str) -> list[dict]:
    """Scan file content for issues. Returns a list of finding dicts."""
    findings = []
    lines = content.split("\n")
    _, ext = os.path.splitext(file_path)
    is_test_file = any(indicator in file_path.lower() for indicator in TEST_INDICATORS)

    for line_num, line in enumerate(lines, start=1):
        # Skip empty lines and comments for performance
        stripped = line.strip()
        if not stripped:
            continue

        # --- Secret patterns ---
        for pattern, description in SECRET_PATTERNS:
            if re.search(pattern, line, re.IGNORECASE):
                findings.append({
                    "rule": "secret",
                    "severity": "HIGH",
                    "file": file_path,
                    "line": line_num,
                    "description": description,
                    "match": stripped[:120],  # Truncate to avoid leaking full secrets
                })

        # --- Dangerous patterns ---
        for pattern, description in DANGEROUS_PATTERNS:
            if re.search(pattern, line):
                findings.append({
                    "rule": "dangerous-pattern",
                    "severity": "MEDIUM",
                    "file": file_path,
                    "line": line_num,
                    "description": description,
                    "match": stripped[:120],
                })

        # --- Debug remnants (skip test files) ---
        if not is_test_file:
            for pattern, description, extensions in DEBUG_PATTERNS:
                # If extensions are specified, only check matching file types
                if extensions is not None and ext.lower() not in extensions:
                    continue
                if re.search(pattern, line):
                    findings.append({
                        "rule": "debug-remnant",
                        "severity": "LOW",
                        "file": file_path,
                        "line": line_num,
                        "description": description,
                        "match": stripped[:120],
                    })

    return findings


def get_content_from_event(event: dict) -> tuple[str, str] | None:
    """Extract file content and path from the tool event.

    Returns (file_path, content) or None if not applicable.
    """
    tool_name = event.get("toolName", "")
    tool_input = event.get("toolInput", {})
    tool_output = event.get("toolOutput", "")

    if tool_name == "Write":
        file_path = tool_input.get("file_path", "")
        content = tool_input.get("content", "")
        if file_path and content:
            return file_path, content

    elif tool_name == "Edit":
        file_path = tool_input.get("file_path", "")
        new_string = tool_input.get("new_string", "")
        if file_path and new_string:
            return file_path, new_string

    elif tool_name == "Bash":
        # For bash commands that write files, we can't easily get the content.
        # The pre-tool hook handles prevention; post-tool checks the output.
        command = tool_input.get("command", "")
        if tool_output and isinstance(tool_output, str):
            # Scan command output for accidentally leaked secrets
            return f"<bash-output:{command[:60]}>", tool_output

    return None


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    try:
        raw = sys.stdin.read()
        if not raw.strip():
            print(json.dumps({"findings": [], "message": "No input received"}))
            return

        event = json.loads(raw)
    except (json.JSONDecodeError, Exception) as e:
        # Never block on parse errors — just warn
        print(json.dumps({
            "findings": [],
            "error": f"Failed to parse input: {str(e)}",
        }))
        return

    result = get_content_from_event(event)
    if result is None:
        print(json.dumps({"findings": [], "message": "No scannable content in event"}))
        return

    file_path, content = result
    findings = scan_content(content, file_path)

    output = {
        "hookSpecificOutput": {
            "hookEventName": "PostToolUse",
        },
        "file": file_path,
        "findings": findings,
        "summary": f"{len(findings)} issue(s) found" if findings else "Clean",
    }

    # Group findings by severity for quick overview
    if findings:
        severity_counts = {}
        for f in findings:
            sev = f["severity"]
            severity_counts[sev] = severity_counts.get(sev, 0) + 1
        output["severity_summary"] = severity_counts

    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()
