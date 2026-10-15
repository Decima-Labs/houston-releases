# Houston

Houston is a Mac app that is both your terminal and mission control for your coding agents. Claude Code and Codex sessions run side by side in it. Houston shows what each one is doing, keeps a short list of what's blocked on you, and lets you jump into any session, take it over, and hand it back.

This repository holds Houston's releases and its Claude Code plugins. Houston's source is private.

## Download

Download `Houston-<version>.dmg` from the [latest release](https://github.com/Decima-Labs/houston-releases/releases/latest), open it, and drag Houston onto Applications. Houston is signed by Decima Labs and notarized by Apple, so it opens like any app from the internet: the first time, macOS asks whether to open it.

Houston keeps itself up to date. It checks this repository for a new release every hour, and **Update Houston…** in the Houston menu checks at once. An update is installed only when you click Update, and only once Houston has checked that the download matches its checksum, that Decima Labs signed it, and that Apple notarized it. Restarting to finish is a click of its own, since quitting Houston closes its terminals. With Gatekeeper turned off, Houston can't check notarization, so it doesn't update itself; download the new release from here instead.

## What you need

- macOS 15 or later, on a Mac with Apple silicon or an Intel processor.
- [Claude Code](https://docs.claude.com/en/docs/claude-code), installed and signed in. Houston starts, watches and attaches to Claude Code sessions through the `claude` command.
- Optional, each lighting up the part of Houston that uses it:
  - [Codex](https://github.com/openai/codex) (`codex`), for Codex sessions beside Claude Code's.
  - [GitHub CLI](https://cli.github.com) (`gh`), signed in, for pull requests, checks and CI.
  - grove (`grove`), for a git worktree per agent.
  - [Vercel CLI](https://vercel.com/docs/cli) (`vercel`), for deployments.

Houston finds these the way your terminal does, through your login shell's PATH. It reads them only through their command-line interfaces. Apart from asking this repository for new releases, it sends nothing anywhere of its own, and it never logs the tokens your shell exports.

## The Claude Code plugin

Houston's plugin streams what each agent is doing to Houston the moment it happens: each prompt, tool call, permission request and stop. Add this repository as a plugin marketplace, then install the plugin:

```bash
claude plugin marketplace add Decima-Labs/houston-releases
claude plugin install houston@houston
```

Sessions you start afterwards load it; in one that's already open, run `/reload-plugins`. To remove it, run `claude plugin uninstall houston@houston`.

## Checking a download yourself

Each release lists the SHA-256 of its disk image, and has it beside the image as `Houston-<version>.dmg.sha256`:

```bash
shasum -a 256 -c Houston-<version>.dmg.sha256
spctl -a -vv -t open --context context:primary-signature Houston-<version>.dmg
```

`spctl` should say `accepted` and `source=Notarized Developer ID`, from Decima Labs' team, 262X2S8YKN.
