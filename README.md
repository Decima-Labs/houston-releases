# Houston

Houston is a Mac app that is both your terminal and mission control for your coding agents. Claude Code and Codex sessions run side by side in it. Houston shows what each one is doing, keeps a short list of what's blocked on you, and lets you jump into any session, take it over, and hand it back.

This repository holds Houston's releases and its Claude Code plugins. Houston's source is private.

## Download

Download `Houston-<version>.dmg` from the [latest release](https://github.com/Decima-Labs/houston-releases/releases/latest), open it, and drag Houston onto Applications. Houston is signed by Apple Developer team 262X2S8YKN and notarized by Apple, so it opens like any app from the internet: the first time, macOS asks whether to open it.

Houston keeps itself up to date. It checks this repository for a new release every hour, and **Update Houston…** in the Houston menu checks at once. An update is installed only when you click Update, and only once Houston has checked that the download matches its checksum, that Apple Developer team 262X2S8YKN signed it, and that Apple notarized it. Restarting to finish is a click of its own, since quitting Houston closes its terminals. With Gatekeeper turned off, Houston can't check notarization, so it doesn't update itself; download the new release from here instead.

## What you need

- macOS 15 or later, on a Mac with Apple silicon or an Intel processor.
- [Claude Code](https://docs.claude.com/en/docs/claude-code), installed and signed in. Houston starts, watches and attaches to Claude Code sessions through the `claude` command.
- Optional, each lighting up the part of Houston that uses it:
  - [Codex](https://github.com/openai/codex) (`codex`), for Codex sessions beside Claude Code's.
  - [GitHub CLI](https://cli.github.com) (`gh`), signed in, for pull requests, checks and CI.
  - git, for a worktree per agent: macOS offers to install it, with Xcode's command line tools, the first time anything runs it.
  - [Vercel CLI](https://vercel.com/docs/cli) (`vercel`), for deployments.

Settings › Integrations also folds one integration under Advanced that most people can't use yet: Claude accounts, which needs cc-acct, an account switcher that isn't published.

Claude Code sessions Houston starts ask you before they run a command, edit a file or use your browser, as Claude Code does anywhere, unless you tick the boxes in Settings › Integrations › Claude Code that let them skip permission prompts or use Claude in Chrome. Houston stops a Claude Code background session left idle for two days, keeping its conversation, and Continue in Houston brings it back; Settings › Integrations › Claude Code sets how long, or Never.

Houston finds these the way your terminal does, through your login shell's PATH. It reads them only through their command-line interfaces. Apart from asking this repository for new releases, it sends nothing anywhere of its own, and it never logs the tokens your shell exports. Houston for iPad isn't on the App Store yet, and runs only when built from Houston's source, so its sharing is off until you turn it on in Settings › Permissions: then Houston writes what it shows to a board in your own iCloud, which only devices signed in to your Apple Account can read.

## The Claude Code plugin

Houston's plugin streams what each agent is doing to Houston the moment it happens: each prompt, tool call, permission request and stop. Houston's welcome offers to install it, with Houston's skills, once Claude Code is on; Settings › Permissions offers it again later. To install it yourself, add this repository as a plugin marketplace, then install the plugin:

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

`spctl` should say `accepted` and `source=Notarized Developer ID`, from Apple Developer team 262X2S8YKN.
