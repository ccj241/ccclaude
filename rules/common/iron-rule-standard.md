---
name: iron-rule-standard
description: "Standard format for iron rules and bans across all roles"
---

# Iron Rule Standard

All role and profile definitions in this project MUST follow these formatting and quality standards for their rules and bans.

## Ban Format

Every ban MUST use this format:

```
- **NEVER [specific action].** Reason: [specific consequence of violation].
- **DO NOT [specific action].** Reason: [specific consequence of violation].
- **CRITICAL: [required action].** Reason: [consequence of not doing it].
```

### Requirements

1. **Every ban MUST have a reason.** Reason: bans without reasons get ignored or wrongly overridden at edge cases. A ban's reason is what allows someone to judge edge cases correctly.

2. **Bans MUST use absolute language.** Use NEVER, DO NOT, CRITICAL, MUST NOT. NEVER use "try to avoid", "preferably don't", "it's best not to", "consider not doing". Reason: soft language gives AI room to self-justify exceptions.

3. **Bans MUST NOT contain escape hatches.** DO NOT write "unless special circumstances", "unless necessary", "when appropriate". Reason: AI can always manufacture special circumstances. If exceptions exist, enumerate them exhaustively.

4. **Bans MUST be verifiable.** If a ban cannot be verified by reading code, reading output, or running a command, it is useless — do not write it. Reason: unverifiable rules provide false confidence.

5. **Bans MUST be specific.** DO NOT write "don't do bad things." Write exactly what action is prohibited and what happens if violated. Reason: vague bans are unenforceable.

## Iron Rule Structure

Every role file MUST contain a `## Iron Rules` section between the Identity section and the Workflow/Protocol section, with:

1. **⛔ Tool Bans** — explicitly list allowed and banned tools with reasons
2. **Numbered Iron Rules** (Iron Rule 0, Iron Rule 1, ...) — each rule is a titled subsection with bullet points
3. Each iron rule contains NEVER/DO NOT/CRITICAL statements with reasons

## Modular Organization

- Group bans by category: tool bans, behavior bans, output bans, boundary bans.
- **Maximum 7 bans per module.** If a module exceeds 7, split into sub-modules.
- **NEVER mix unrelated bans in the same paragraph.** Each ban is its own bullet point.

## Conclusion-First Principle

All role outputs MUST follow conclusion-first ordering:
- State the result/verdict/answer first
- Provide reasoning/evidence second
- **DO NOT lead with preamble, context, or background before the conclusion**
