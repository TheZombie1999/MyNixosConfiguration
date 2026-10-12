# Task 4 — Make SSH key trust fully declarative on hetzner-nbg1

## Goal

Close a latent persistence vector on `hetzner-nbg1`: right now `sshd` trusts both the
Nix-managed key list *and* a manually-droppable `~/.ssh/authorized_keys` per user.
`nixos-rebuild`/`deploy-rs` never inspects or clears the latter, so a single moment of
write access as `root` or `tim` could plant a key there that survives every future
redeploy silently and invisibly. This task makes `/etc/ssh/authorized_keys.d/%u` (the
Nix-managed one) the *only* trusted source.

This was identified during the general hardening pass on `hetzner-nbg1.nix` (see repo
history) — a first attempt to fix it landed but turned out to be a no-op; this doc
exists so the next attempt doesn't have to re-derive why.

## Current state (confirmed live on the box, 2026-10-12)

`sshd -T` on `hetzner-nbg1` shows:
```
AuthorizedKeysFile /etc/ssh/authorized_keys.d/%u %h/.ssh/authorized_keys /etc/ssh/authorized_keys.d/%u
```
Both `root`'s and `tim`'s `~/.ssh/authorized_keys` are currently empty/absent, so nothing
is actively exploited — but the home-dir path is still live and trusted.

## Why the first attempt didn't work

`Maschines/hetzner-nbg1.nix` currently has:
```nix
services.openssh = {
  enable = true;
  authorizedKeysFiles = [ "/etc/ssh/authorized_keys.d/%u" ];
  settings = { ... };
};
```
This looked right but does nothing, because nixpkgs's own sshd module
(`nixos/modules/services/networking/ssh/sshd.nix`, verified against the pinned
`nixos-26.05` source) makes a *second* assignment to the same option:
```nix
services.openssh.authorizedKeysFiles =
  lib.optional cfg.authorizedKeysInHomedir "%h/.ssh/authorized_keys"
  ++ [ "/etc/ssh/authorized_keys.d/%u" ];
```
`authorizedKeysFiles` is a `listOf str` — NixOS's module system concatenates multiple
definitions of a list option rather than letting one override another. So whatever
gets set in `hetzner-nbg1.nix` is *added to*, not instead of, the module's own default
list. That's why the home-dir entry survived (and why it shows up twice in the final
`sshd -T` output above — once from each assignment).

## The actual fix

The module exposes the real knob for this, `services.openssh.authorizedKeysInHomedir`
(default `true`, per the same source file):
```nix
description = ''
  Enables the use of the `~/.ssh/authorized_keys` file.

  Otherwise, the only files trusted by default are those in
  `/etc/ssh/authorized_keys.d`, *i.e.* SSH keys from
  `users.users.<name>.openssh.authorizedKeys.keys`.
'';
```

### Change to `Maschines/hetzner-nbg1.nix`

Replace the current no-op line:
```nix
authorizedKeysFiles = [ "/etc/ssh/authorized_keys.d/%u" ];
```
with:
```nix
authorizedKeysInHomedir = false;
```
This goes directly under `services.openssh = { ... };` (as a sibling of `enable` and
`settings`, not inside `settings` — it's a module-level option, not an sshd_config
setting). The `authorizedKeysFiles` list option should be left alone entirely; once
`authorizedKeysInHomedir = false`, the module's own default already resolves to just
`[ "/etc/ssh/authorized_keys.d/%u" ]`.

## Verification

1. Deploy, then on the box: `sshd -T | grep -i authorizedkeysfile` → expect exactly
   `AuthorizedKeysFile /etc/ssh/authorized_keys.d/%u` (single entry, no `%h/.ssh/...`,
   no duplication).
2. As a destructive-but-reversible test (take a backup first, or do this on a throwaway
   key): temporarily write a test public key into `/root/.ssh/authorized_keys` on the
   live box directly (not through Nix) and confirm `ssh` with that key is **refused** —
   proves the home-dir path is no longer trusted. Remove the test file afterward.
3. Confirm normal login still works with the existing `sk-ssh-ed25519` key for both
   `root` and `tim` (the Nix-managed `/etc/ssh/authorized_keys.d/%u` path is untouched
   by this change).

## Critical files

- `/home/tim/OneDev/MyNixosConfiguration/Maschines/hetzner-nbg1.nix`
