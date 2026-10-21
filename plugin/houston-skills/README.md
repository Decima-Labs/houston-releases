# houston-skills

Engineering skills for Claude Code, and a short set of working rules added to every session. Claude Code reaches for a skill when the work calls for it, or you can call one by name: `/houston-skills:tdd`.

## Install

```bash
claude plugin install houston-skills --marketplace Decima-Labs/houston-releases
```

That adds the `houston` marketplace and installs the plugin for every project. Sessions you start afterwards load it; in a session that's already open, run `/reload-plugins`. Houston's first-run flow runs the same install in one click. To remove it: `claude plugin uninstall houston-skills@houston`.

## The skills

| Skill | Use it to |
|---|---|
| `code-review` | Review a branch, a PR or work in progress against the repo's standards, the spec it came from, and its security surface, each in a sub-agent of its own |
| `tdd` | Build or fix test-first, one red → green slice at a time, at seams agreed up front |
| `diagnosing-bugs` | Work a hard bug or a performance regression from a tight feedback loop to a regression test |
| `grilling` | Have a plan, decision or idea questioned until every branch of it is settled |
| `resolving-merge-conflicts` | Finish an in-progress merge or rebase hunk by hunk, then run the project's checks |
| `stacked-prs` | Build, update and merge a chain of dependent pull requests |
| `frontend-design` | Build interfaces that are simple, obvious to use, accessible and checked rendered |
| `apple-design` | Make motion, materials and type feel fluid: springs, gestures, translucency, reduced motion |
| `codebase-design` | Design deep modules: small interfaces, clean seams, code that is easy to test |
| `domain-modeling` | Sharpen a project's vocabulary in `CONTEXT.md`, and record hard decisions as ADRs |
| `research` | Have a background agent answer a question from primary sources and write the findings down |
| `writing-for-agents` | Write skills, `CLAUDE.md` and other documents an agent reads |
| `prototype` | Answer a design question with throwaway code: a logic demo or several UI variants |

## The working rules

A SessionStart hook adds [`rules/rules.md`](rules/rules.md) to every session as context, for a new session, a resumed one, after `/clear` and after a compaction. In short: ask the question you have, match the ceremony to the ask, finish the whole scope, answer first and briefly, keep things up, keep secrets in the environment, and scale tests with the work. Your own `CLAUDE.md` and instructions outrank them.

To turn the rules off and keep the skills, use either:

- the plugin's **Working rules** option: the switch on the plugin's row in Houston's Toolkit › Plugins, `claude plugin configure houston-skills@houston` (or `/plugin configure houston-skills@houston` in a session), or `--config rules=false` when you install;
- `HOUSTON_RULES=off` in the environment Claude Code runs in, such as `"env": { "HOUSTON_RULES": "off" }` in `~/.claude/settings.json`. `0`, `false` and `no` work too.

Either one turns them off. The hook prints nothing then, and it always exits 0, so a session never fails to start over it.

## Where the skills come from, and their licences

| Skills | Source | Licence |
|---|---|---|
| `code-review`, `tdd`, `diagnosing-bugs`, `grilling`, `resolving-merge-conflicts`, `codebase-design`, `domain-modeling`, `research`, `writing-for-agents`, `prototype` | [mattpocock/skills](https://github.com/mattpocock/skills), adapted | MIT, Copyright (c) 2026 Matt Pocock: each folder's `LICENSE` |
| `apple-design` | [emilkowalski/skills](https://github.com/emilkowalski/skills), adapted | MIT, Copyright (c) 2026 Emil Kowalski: `apple-design/LICENSE` |
| `frontend-design` | [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/frontend-design), rewritten | Apache License 2.0: `frontend-design/LICENSE.txt` |
| `stacked-prs`, the working rules | Decima Labs | All rights reserved |

The adapted skills keep their own licences: each of those folders carries its MIT or Apache License 2.0 text, and what that licence allows still applies to it here. They are changed to stand on their own: references to tools and skills that don't ship here are gone or point at the skill that does.

`stacked-prs` and the working rules are Decima Labs' own, and each carries this notice:

Copyright © 2026 Decima Labs. All rights reserved. Use through Houston and Claude Code; not for redistribution.
