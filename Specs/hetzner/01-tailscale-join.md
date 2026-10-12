# Task 1 — Join hetzner-nbg1 to the Tailscale tailnet

## Goal

`hetzner-nbg1` is a public-facing NixOS VM (IPv6-only, no public IPv4) that already
serves `https://hetzner.nixhomelab.de` over a real Let's Encrypt cert via nginx. This
task makes it a member of the existing home-lab Tailscale tailnet, so it can reach
home-lab services privately instead of over the public internet.

This is the foundation for [02-oauth2-proxy-auth.md](./02-oauth2-proxy-auth.md) (same
host, independent feature) and a hard prerequisite for
[03-ssh-bastion.md](./03-ssh-bastion.md) (the SSH bastion jumps *through* this host's
tailnet membership).

Decision locked in: reuse the existing tailnet (already running — `proxmox1` offers
itself as an exit node / subnet router, `moab` is a peer) rather than stand up a
dedicated WireGuard link.

## Current state (verified by direct inspection)

- `Maschines/hetzner-nbg1.nix` has no sops/tailscale wiring today; module signature is
  `{ pkgs, ... }:`.
- `flake.nix`'s `hetzner-nbg1` entry passes no `specialArgs` — needed to get `inputs`
  in scope for the sops-nix module.
- `.sops.yaml` has 3 anchors (`primary`, `yubikey`, `moab`); `Maschines/moab.nix`
  already demonstrates the exact pattern needed here (`sops.age.sshKeyPaths` derived
  from the host's own SSH host key, instead of a manually-placed `keys.txt` —
  appropriate since this is a disposable cloud box). **Do not touch `moab.nix`.**
- Host's current SSH ed25519 pubkey converts (via `ssh-to-age`) to age pubkey
  `age1llrhf0c2767ak54k7m9hla8h5aqcj3qrl2a7wmz02wj9uzluu34qq26juj` — re-derive at
  execution time in case it rotated.
- Verified real `services.tailscale` options (nixpkgs `nixos-26.05` source, not
  guessed): `enable`, `authKeyFile`, `openFirewall` (opens the UDP port on both v4+v6
  chains — fine for an IPv6-only box), `useRoutingFeatures` (`"client"` sets
  `networking.firewall.checkReversePath = "loose"`, correct for a node that *accepts*
  routes), `extraUpFlags` (only applied when `authKeyFile` is set — `--accept-routes`
  goes here; there's no separate declarative "accept routes" option).

## Changes

**`flake.nix`** — add `specialArgs` to the `hetzner-nbg1` entry:
```nix
"hetzner-nbg1" = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = { inherit inputs; };
  modules = [ ./Maschines/hetzner-nbg1.nix ];
};
```

**`Maschines/hetzner-nbg1.nix`** — header becomes `{ pkgs, config, inputs, ... }:`;
add to `imports`: `inputs.sops-nix.nixosModules.sops`; add:
```nix
sops.defaultSopsFile = ../Secrets/secrets.yaml;
sops.defaultSopsFormat = "yaml";
sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
sops.secrets.hetzner_tailscale_key = { };

services.tailscale = {
  enable = true;
  authKeyFile = config.sops.secrets."hetzner_tailscale_key".path;
  openFirewall = true;
  useRoutingFeatures = "client";
  extraUpFlags = [ "--accept-routes" ];
};
```

**`.sops.yaml`** — add anchor `&hetzner-nbg1` with the age pubkey above, add it to the
existing single key group for `Secrets/secrets\.yaml$`.

**`Secrets/secrets.yaml`** — via `sops Secrets/secrets.yaml`, add `hetzner_tailscale_key`
(the real Tailscale auth key, see manual steps below). Follow with `sops updatekeys
Secrets/secrets.yaml` as a safety net.

## Manual steps (user, in Tailscale admin console — cannot be scripted)

1. Create a **reusable, non-ephemeral** Tailscale auth key (this box may be rebuilt —
   an ephemeral/one-shot key would strand it). Tag it if the tailnet uses ACL tags.
2. Confirm `proxmox1`'s advertised subnet route is **approved** (separate from any
   client's `--accept-routes` flag — approval is an admin-console action, not visible
   from `tailscale status` CLI output).
3. Hand the raw key value over for the `sops` edit step — never committed in plaintext.

## Secret to add via `sops Secrets/secrets.yaml`

```yaml
hetzner_tailscale_key: <tailscale auth key>
```

## Deploy

```
deploy .#hetzner-nbg1 --skip-checks --auto-rollback false --magic-rollback false
```
(`--skip-checks` needed because of a cosmetic `dbus-broker` reload false-positive on
this host, and an unrelated broken `bootstrap` nixosConfiguration tripping `nix flake
check`.)

## Verification

1. `ssh root@2a01:4f8:1c1c:8a66::1 systemctl status tailscaled tailscaled-autoconnect`
   — active.
2. `tailscale status` on the box — no `NeedsLogin`, shows tailnet peers.
3. Locally, `tailscale status` now shows `hetzner-nbg1` online.
4. From the box, `ping -c3 100.87.237.46` (proxmox1) — basic peer reachability.
5. Ping an address *inside* proxmox1's advertised home-LAN CIDR (not a tailnet node
   itself) — this is what actually proves route *acceptance*, distinct from #4. If this
   fails but #4 works, suspect the route isn't *approved* server-side (manual step
   above), not a Nix misconfiguration.

## Out of scope here

No HTTP home-lab backend gets proxied yet, and no SSH bastion config — those are
[02-oauth2-proxy-auth.md](./02-oauth2-proxy-auth.md) and
[03-ssh-bastion.md](./03-ssh-bastion.md) respectively. No changes to `Maschines/moab.nix`.

## Critical files

- `/home/tim/OneDev/MyNixosConfiguration/Maschines/hetzner-nbg1.nix`
- `/home/tim/OneDev/MyNixosConfiguration/flake.nix`
- `/home/tim/OneDev/MyNixosConfiguration/.sops.yaml`
- `/home/tim/OneDev/MyNixosConfiguration/Secrets/secrets.yaml`
- `/home/tim/OneDev/MyNixosConfiguration/Maschines/moab.nix` (reference only, do not modify)
