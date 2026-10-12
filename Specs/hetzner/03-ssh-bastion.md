# Task 3 — SSH bastion through hetzner-nbg1 to nixos-onedev

## Goal

Give the user a way to SSH into specific internal servers (starting with
`nixos-onedev`) **without requiring Tailscale on the client**. The real-world
constraint: the user sometimes uses a machine that's already enrolled in a *different*
Tailscale tailnet (e.g. a work laptop — only one tailnet login per device), so they
need a path to specific home-lab servers that doesn't depend on the client itself
being on the home tailnet.

Solved via an SSH bastion/jump through `hetzner-nbg1` (which *is* always on the
tailnet after [01-tailscale-join.md](./01-tailscale-join.md)), restricted per-key to
specific targets via OpenSSH `permitopen` — not a generic "SSH to anything," and not
Tailscale SSH (which still requires the client to be on the tailnet).

**Hard prerequisite**: [01-tailscale-join.md](./01-tailscale-join.md) must be deployed
first — this task relies on `hetzner-nbg1` already being a tailnet member.

## Current state

`nixos-onedev` (the git server LXC) has **no Tailscale config at all** today — it's
only reachable via its Proxmox host's local LXC bridge. To jump to it through
`hetzner-nbg1`, it must join the tailnet first, exactly like Task 1 but for a
different host.

`nixos-onedev` is currently **not** in the "do not touch" list — only
`Maschines/microstar.nix`/`Maschines/moab.nix` stay untouched.

## 3a. Join `nixos-onedev` to the tailnet

Same pattern as Task 1, applied to `Maschines/nixos-onedev.nix`:

- `flake.nix`: add `specialArgs = { inherit inputs; };` to the `"nixos-onedev"`
  `nixosConfigurations` entry (currently has none, same gap Task 1 fixed for
  `hetzner-nbg1`).
- `nixos-onedev.nix`: add `inputs.sops-nix.nixosModules.sops` to `imports`; add:
  ```nix
  sops.defaultSopsFile = ../Secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.secrets.onedev_tailscale_key = { };

  services.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets."onedev_tailscale_key".path;
    openFirewall = true;
  };
  ```
  (No `useRoutingFeatures`/`extraUpFlags` needed — this host only needs to be *reachable*
  on the tailnet, not accept routes to other subnets.)
- `.sops.yaml`: add a new `&onedev` anchor (derive its age pubkey from its SSH host
  key the same way as Task 1 — need to confirm this machine can reach it, e.g. via
  `ssh tim@nixos-onedev` as `deploy.nodes.nixos-onedev` already does; if not reachable
  from here, this step runs from wherever that hostname does resolve).
- `Secrets/secrets.yaml`: add `onedev_tailscale_key` (another reusable, non-ephemeral
  Tailscale auth key — same manual admin-console step as Task 1).
- Deploy via the existing `deploy.nodes.nixos-onedev` target: `deploy .#nixos-onedev`.

**Ordering dependency**: `nixos-onedev` must actually join and be assigned a tailnet IP
*before* step 3b below can reference it — `tailscale status` after this deploy reveals
the real address (Tailscale doesn't let you pre-pick it declaratively here).

## 3b. Dedicated restricted "jump" user on `hetzner-nbg1`

**Note**: the server-hardening pass (see repo history on `Maschines/hetzner-nbg1.nix`)
set `services.openssh.settings.AllowTcpForwarding = false;` globally, since nothing
needed port forwarding at the time. `permitopen` grants nothing on its own if
`AllowTcpForwarding` is off for the connecting user — this task must add a `Match`
override scoped to the `jump` user alongside the block below, or the bastion will
silently fail to forward anything:
```nix
services.openssh.extraConfig = ''
  Match User jump
    AllowTcpForwarding yes
'';
```

Add to `Maschines/hetzner-nbg1.nix`:
```nix
users.users.jump = {
  isNormalUser = true;
  shell = pkgs.shadow; # no interactive shell needed, ProxyJump only uses direct-tcpip
  openssh.authorizedKeys.keys = [
    ''command="echo 'Bastion: port-forwarding only'",no-agent-forwarding,no-X11-forwarding,no-pty,permitopen="<nixos-onedev-tailnet-ip>:22" sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIK5ynhdh9jUSrKGll4ZOw4Krji+ipGNfsFKu6EmbEpVMAAAABHNzaDo=''
  ];
};
```
Also add `"jump"` to `services.openssh.settings.AllowUsers` in the same file (that
list was introduced by the same hardening pass and defaults to only `root`/`tim` —
without it, the `jump` user can't authenticate at all).
- `permitopen` pins this key to *only* open a tunnel to `nixos-onedev`'s tailnet
  address on port 22 — not proxmox1, not microstar, nothing else reachable from
  Hetzner's tailnet membership. Adding another server later means adding another
  `permitopen` entry (or another key), not opening up access generally.
- `command=` neutralizes any attempt to get an actual shell/exec on `hetzner-nbg1`
  itself with this key — port-forwarding still works since `permitopen` is a separate
  grant from `command=`.
- Verify at execution time whether this OpenSSH version accepts a MagicDNS hostname
  (e.g. `nixos-onedev.<tailnet>.ts.net:22`) in `permitopen` instead of a raw IP — more
  robust if the device's IP ever changes — falling back to the concrete IP if not.
- No new firewall port — this rides the existing public port 22 `hetzner-nbg1` already
  has open.

## Usage

```
ssh -J jump@hetzner.nixhomelab.de tim@<nixos-onedev-tailnet-ip>
```
Works from any machine with the right key, regardless of whether *that* machine is on
the home tailnet at all — solves the "work laptop on a different tailnet" case
directly.

## Deploy

```
deploy .#nixos-onedev --skip-checks --auto-rollback false --magic-rollback false
deploy .#hetzner-nbg1 --skip-checks --auto-rollback false --magic-rollback false
```
Deploy 3a (`nixos-onedev`) first — 3b needs its real tailnet IP. `--skip-checks`
needed because of a cosmetic `dbus-broker` reload false-positive on `hetzner-nbg1`,
and an unrelated broken `bootstrap` nixosConfiguration tripping `nix flake check`.

## Verification

1. After 3a deploys, `ssh tim@nixos-onedev tailscale ip -4` (or check the admin
   console) — get the real tailnet IP, confirm it shows as an online peer locally too.
2. After 3b deploys, from a machine that is *not* on the home tailnet:
   `ssh -J jump@hetzner.nixhomelab.de tim@<that-ip>` — should land on `nixos-onedev`.
3. From the same jump key, attempt `ssh jump@hetzner.nixhomelab.de` directly (no `-J`,
   i.e. trying to get a shell on Hetzner itself) — should print the `command=` message
   and disconnect, not grant a shell.
4. Attempt `-J jump@hetzner.nixhomelab.de` toward a *different* tailnet address (e.g.
   `microstar`'s or `proxmox1`'s) — should be refused by `permitopen`, confirming the
   restriction is per-target, not "anything Hetzner can reach."

## Out of scope here

No changes to `Maschines/microstar.nix` or `Maschines/moab.nix`. No generic Tailscale
SSH setup — this is strictly the `permitopen`-restricted bastion pattern.

## Critical files

- `/home/tim/OneDev/MyNixosConfiguration/Maschines/hetzner-nbg1.nix`
- `/home/tim/OneDev/MyNixosConfiguration/Maschines/nixos-onedev.nix`
- `/home/tim/OneDev/MyNixosConfiguration/flake.nix`
- `/home/tim/OneDev/MyNixosConfiguration/.sops.yaml`
- `/home/tim/OneDev/MyNixosConfiguration/Secrets/secrets.yaml`
- `/home/tim/OneDev/MyNixosConfiguration/Maschines/moab.nix` (reference only, do not modify)
