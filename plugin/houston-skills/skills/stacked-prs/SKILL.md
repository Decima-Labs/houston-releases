---
name: stacked-prs
description: Use when a dependent chain of changes needs stacked PRs (change B builds on unmerged change A): how to build, update and merge the stack, and the one-stack-one-worktree rule. Not for independent changes, which stay one flat PR each.
---

# Stacked PRs for dependent chains

When change B builds on unmerged change A, don't serialise (branch → PR → wait for review → rebase → next). **Stack them**: one branch and one PR per layer, each PR based on the branch below it, so review of the lower layers runs while you build the upper ones. Independent changes are not a stack: each stays one branch and one flat PR against the default branch.

## Building the stack

- **Name the layers in order** so the stack reads at a glance: `feature/1-model`, `feature/2-api`, `feature/3-ui`.
- **Base each PR on the layer below**, not on the default branch: `gh pr create --base feature/1-model` for layer 2. Its diff then shows only its own change.
- **Say it's a stack** in each PR body: the layer below, the layer above, and that it merges bottom-up.
- Keep each layer reviewable on its own: it builds, its tests pass, and it makes sense without the layers above.

If GitHub's `gh stack` extension is installed (`gh extension list`), it does the bookkeeping: `gh stack init`, a commit, `gh stack add <branch>` per layer, `gh stack submit` to create or update every PR, `gh stack sync` after remote changes. Check `gh stack --help` for the version you have; it changes quickly.

## Updating a lower layer

Commit the fix on the lower branch, then carry it up through every branch above it:

```bash
git checkout feature/3-ui
git rebase --update-refs feature/1-model   # moves 2 and 3 onto the new 1 in one go
git push --force-with-lease origin feature/2-api feature/3-ui
```

`--update-refs` moves every intermediate branch the rebase passes through. Push with `--force-with-lease`, never a bare `--force`, so a push someone else made to a layer isn't overwritten.

## Merging

Merge bottom-up, one layer at a time. When a layer merges, retarget the PR above it to the default branch (GitHub does this when the merged branch is deleted, and `gh stack` does it for you), let its checks pass on the new base, then merge it. Never merge an upper layer first: it would carry every layer below it in with it.

Deleting a merged layer's branch can close the PR based on it rather than retargeting it. Retarget the PR above first, then delete.

## One stack = one worktree = one agent

Git refuses to change a branch that's checked out in another worktree, and `git rebase --update-refs` **silently skips** such branches, leaving a half-moved stack with no error. Keep every branch of one stack in a single worktree, worked by one agent. Run independent stacks in parallel, never the layers of one stack.

## Everything else is unchanged

Each layer is still a normal branch and PR: the project's review rules, its CI and its rules for the default branch apply to every layer. A layer isn't done until its checks are green on its current base.

---

Copyright © 2026 Decima Labs. All rights reserved. Use through Houston and Claude Code; not for redistribution.
