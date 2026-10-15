# Houston's Claude Code plugins

This folder is a Claude Code marketplace called `houston`, published by Decima Labs, with two plugins that install separately:

| Plugin | What it does |
|---|---|
| [`houston`](houston/README.md) | Streams what each Claude Code agent is doing to Houston, the Mac app. Useful only with Houston running. |
| [`houston-skills`](houston-skills/README.md) | Thirteen engineering skills, and a short set of working rules added to every session. Useful anywhere Claude Code runs. |

The skills adapted from others keep their own MIT or Apache License 2.0 licences; [`houston-skills/README.md`](houston-skills/README.md#where-the-skills-come-from-and-their-licences) lists them, and what is Decima Labs' own.

## Install

From the public marketplace, which needs no Houston checkout:

```bash
claude plugin marketplace add Decima-Labs/houston-releases
claude plugin install houston-skills@houston
claude plugin install houston@houston
```

From a Houston checkout at `~/code/houston`, which Claude Code then reads in place:

```bash
claude plugin install houston-skills --marketplace ~/code/houston/plugin
claude plugin install houston --marketplace ~/code/houston/plugin
```

Houston's first-run flow and its Settings install `houston-skills` for you, and Houston's Access screen installs `houston`. Claude Code keeps one marketplace called `houston`: whichever of the two you add first is the one both plugins come from. To switch, run `claude plugin marketplace remove houston` and add the other.

## Publishing

`Decima-Labs/houston-releases` carries this folder's contents at its root, so `.claude-plugin/marketplace.json` sits at the top of that repository, where `claude plugin marketplace add Decima-Labs/houston-releases` looks for it. Raise a plugin's `version` in its `.claude-plugin/plugin.json` whenever it changes: Claude Code keeps each version installed from a repository apart, and `claude plugin update` only moves to a version it hasn't got.

`claude plugin validate plugin` checks the marketplace, and `claude plugin validate plugin/houston` and `claude plugin validate plugin/houston-skills` each plugin. The tests in `Tests/HoustonCoreTests/HookPluginTests.swift` and `Tests/HoustonCoreTests/SkillsPluginTests.swift` check the manifests and run both plugins' scripts.
