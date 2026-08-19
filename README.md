# homebrew-tap

Homebrew tap for [rackctl](https://github.com/rackctl/rackctl) CLIs.

```sh
brew install rackctl/tap/rackctl
```

Not on Homebrew? The installer covers macOS and Linux for the same binaries:

```sh
curl -fsSL rackctl.sh/install | sh
```

Use `rackctl.sh`. The other rackctl domains serve a holding page, so
`curl -fsSL rackctl.com/install | sh` would pipe HTML to your shell — `-f` does not
save you there, because the holding page returns HTTP 200.

## `rackctl.rb` is generated — do not edit it

The formula carries goreleaser's `DO NOT EDIT` header, and it means it. `rackctl.rb`
is regenerated from the `brews:` block of
[`.goreleaser.yaml`](https://github.com/rackctl/rackctl/blob/main/.goreleaser.yaml)
in the `rackctl/rackctl` repo on every release, so anything you change here — the
description, the install body, a hand-added `test do` — is silently overwritten by
the next one. Fix it at the generator instead.

## Releasing

Releases are cut from `rackctl/rackctl`, not from here. On each release goreleaser
opens a PR against this repo bumping the formula; `main` is protected by a no-bypass
ruleset, so the bot cannot push directly.

1. Tag and release in `rackctl/rackctl`.
2. goreleaser opens a formula-bump PR here.
3. CI runs: the binary is installed and executed, and every SHA256 the formula
   declares is checked against the release's published `checksums.txt`.
4. Merge on green.

To verify a formula's checksums locally at any time:

```sh
./script/verify-checksums.sh rackctl.rb
```
