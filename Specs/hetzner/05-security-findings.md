# Security findings from the Tailscale join / bastion work (2026-10-12/13)

Notes collected while building and verifying the `hetzner-nbg1` → `nixos-onedev`
jump bastion ([01-tailscale-join.md](./01-tailscale-join.md),
[03-ssh-bastion.md](./03-ssh-bastion.md)). Not acted on yet — this is a punch list
to work through later, roughly ordered by how much it's actually worth worrying
about.

## 1. `onedev` container's root key reuses the fleet-wide key (worth fixing first)

While wiring up the bastion, `tim@192.168.178.101` (the `onedev` git-server LXC,
container 101 on `proxmox1`) turned out to have no `tim` user at all — only `root`,
with no `authorized_keys`. To get SSH working there, the same
`sk-ssh-ed25519@openssh.com` key already used as `tim` on every other host
(`moab`, `hetzner-nbg1`, `nixos-onedev`) and as the restricted `jump` bastion key
on `hetzner-nbg1` was added to `/root/.ssh/authorized_keys` on that container
directly via `pct exec` (not declarative, not in this repo — won't survive a
container rebuild).

**Why it matters**: one key now equals root on `onedev`, `tim` everywhere else in
the fleet, and bastion access. If that key/device were ever cloned or
compromised, the blast radius is the whole fleet plus root on an appliance box
that's otherwise fairly minimal.

**Possible fix**: a separate resident key on the same FIDO device (or a distinct
key entirely) for that one account, so it can be revoked independently without
touching anything else. Also worth deciding whether `onedev` should get a real
`tim` user (matching the rest of the fleet) instead of relying on `root`.

## 2. `PermitOpen`/`permitopen=` interaction is a footgun for future bastion targets

Verified live during this work: `authorized_keys` `permitopen=` does **not**
narrow access the way its name suggests once an explicit `PermitOpen` directive
exists anywhere in scope. The actual enforcement for the `jump` user's single
allowed destination now lives in `Maschines/hetzner-nbg1.nix`'s
`services.openssh.extraConfig` (`Match User jump { PermitOpen
192.168.178.103:22; }`), **not** in the `permitopen=` option on the key itself
(which is now redundant documentation at best).

**Why it matters**: the "obvious" way to add a second jump target — just adding
another `permitopen=` entry to the `jump` user's key — will silently do nothing,
reproducing the exact bypass bug found and fixed in commits `a5accd0`→`5e73dbb`.
The `Match`-block `PermitOpen` list must be updated too, every time.

**Possible fix**: nothing urgent now (comment already left in the file as a
reminder); just don't forget this when the bastion grows to cover more hosts.

## 3. fail2ban on `hetzner-nbg1` exempts the whole Tailscale CGNAT range

`services.fail2ban.ignoreIP` includes `100.64.0.0/10`, so any device on the
tailnet — including personal devices like a phone or Windows laptop, not just
other servers — is exempt from brute-force banning against `jump`/`tim` on
`hetzner-nbg1`.

**Why it matters**: low risk since auth is still key-only, but it's a wider
exemption than "just my other servers," and widens if more personal devices
join the tailnet later.

**Possible fix**: scope the exemption to just the server peers (`proxmox1`,
`moab`, etc.) if that's easy to pin, or accept this as-is given key-only auth
already blocks the actual attack this guards against.

## 4. Inconsistent root-login posture between hosts

`onedev`'s sshd has `PermitRootLogin yes` (unrestricted — this predates today's
work, not something introduced by it). `hetzner-nbg1` deliberately set
`PermitRootLogin no` and routes all privileged access through `tim` + sudo
instead, per its hardening pass.

**Why it matters**: not exploitable on its own (still key-only), but it's an
inconsistent posture across the fleet worth aligning if that container ever gets
more attention.

## 5. `hetzner-nbg1`'s Tailscale auth key is a standing credential if the box is compromised

`hetzner-nbg1` decrypts its own Tailscale auth key via sops (its own SSH host
key as the age identity) to join the tailnet. Per
[01-tailscale-join.md](./01-tailscale-join.md) this should be a reusable,
non-ephemeral key (needed so the box can rejoin after a rebuild).

**Why it matters**: if `hetzner-nbg1` (a public-facing VPS) is ever compromised,
that key could in principle be reused to mint a rogue device onto the tailnet,
independent of whatever the SSH bastion itself restricts.

**Possible fix**: none needed unless/until it's actually used that way — just
know it's revocable in the Tailscale admin console if `hetzner-nbg1` is ever
suspected compromised, and rotate it as part of incident response.

## Not a finding, just a design tradeoff worth remembering

`hetzner-nbg1` is now a stepping stone from the public internet into the home
LAN (via the accepted `192.168.178.0/24` subnet route + the `jump` bastion).
That's the intended point of building this, but it does raise the stakes of a
`hetzner-nbg1` compromise compared to before, when it was "just" a single VPS
with no home-network reach.
