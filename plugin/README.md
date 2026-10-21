# Houston's Claude Code plugins

This folder is a Claude Code marketplace called `houston`, published by Decima Labs, with two plugins that install separately:

| Plugin | What it does |
|---|---|
| [`houston`](houston/README.md) | Streams what each Claude Code agent is doing to Houston, the Mac app, and gives it a progress tool whose plans and time left Houston shows. Useful only with Houston running. |
| [`houston-skills`](houston-skills/README.md) | Thirteen engineering skills, and a short set of working rules added to every session. Useful anywhere Claude Code runs. |

The skills adapted from others keep their own MIT or Apache License 2.0 licences; [`houston-skills/README.md`](houston-skills/README.md#where-the-skills-come-from-and-their-licences) lists them, and what is Decima Labs' own.

## Install

```bash
claude plugin marketplace add Decima-Labs/houston-releases
claude plugin install houston-skills@houston
claude plugin install houston@houston
```

Houston's first-run flow installs `houston-skills` for you, and Houston's Settings › Permissions installs `houston`. Sessions you start afterwards load them; in a session that's already open, run `/reload-plugins`.
