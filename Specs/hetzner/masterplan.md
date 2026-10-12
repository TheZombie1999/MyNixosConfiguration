# Hetzner Gateway → Home-Lab: Tailscale Join + Auth Gate

## Context

`hetzner-nbg1` is a public-facing NixOS VM (IPv6-only, no public IPv4) that already
serves `https://hetzner.nixhomelab.de` over a real Let's Encrypt cert via nginx. The
goal is to turn it into a secure public gateway into the home-lab: reachable from the
internet, but (a) able to reach home-lab services privately over the existing Tailscale
tailnet, and (b) never exposing anything without authentication first.

Three decisions are locked in:
- **Tunnel**: reuse the existing Tailscale tailnet (already running: `proxmox1` offers
  itself as an exit node / subnet router, `moab` is a peer) rather than a dedicated
  WireGuard link.
- **Web auth**: `oauth2-proxy` in front of nginx, authenticating against **GitHub**,
  restricted to the user's own GitHub account only (not org-wide, not "any GitHub
  user").
- **SSH access to specific internal servers, without requiring Tailscale on the
  client**: the user's real-world constraint is that they sometimes use a machine
  that's already enrolled in a *different* Tailscale tailnet (e.g. a work laptop —
  only one tailnet login per device), so they need a path to specific home-lab
  servers that doesn't depend on the client itself being on the home tailnet. Solved
  via an SSH bastion/jump through `hetzner-nbg1` (which *is* always on the tailnet),
  restricted per-key to specific targets via OpenSSH `permitopen` — not a generic "SSH
  to anything," and not Tailscale SSH (which still requires the client to be on the
  tailnet).

**Explicitly out of scope for this round**: no HTTP home-lab backend gets proxied yet.
The existing "Hello World" page becomes the one concrete, end-to-end test of the whole
web-auth chain (DNS → TLS → GitHub login → page content) — not a real service. The
Minecraft/`nginx stream`-block TCP-forwarding pattern discussed for non-HTTP services
is documented as a future pattern, not implemented.

## Part 1 — Join the tailnet

Confirmed by direct inspection this session (host SSH'd into, nixpkgs `nixos-26.05`
module source read, local `tailscale status` run, `.sops.yaml`/`secrets.yaml` read):

- `hetzner-nbg1.nix` has no sops/tailscale wiring today; module signature is `{ pkgs, ... }:`.
- `flake.nix`'s `hetzner-nbg1` entry passes no `specialArgs` — needed to get `inputs` in scope.
- `.sops.yaml` has 3 anchors (`primary`, `yubikey`, `moab`); `moab.nix` already
  demonstrates the exact pattern needed here (`sops.age.sshKeyPaths` derived from the
  host's own SSH host key, instead of a manually-placed `keys.txt` — appropriate since
  this is a disposable cloud box). **Do not touch `moab.nix`** — its in-flight changes
  are from another session.
- Host's current SSH ed25519 pubkey converts (via `ssh-to-age`) to age pubkey
  `age1llrhf0c2767ak54k7m9hla8h5aqcj3qrl2a7wmz02wj9uzluu34qq26juj` — re-derive at
  execution time in case it rotated.
- Verified real `services.tailscale` options (nixpkgs `nixos-26.05` source, not
  guessed): `enable`, `authKeyFile`, `openFirewall` (opens the UDP port on both v4+v6
  chains — fine for an IPv6-only box), `useRoutingFeatures` (`"client"` sets
  `networking.firewall.checkReversePath = "loose"`, correct for a node that *accepts*
  routes), `extraUpFlags` (only applied when `authKeyFile` is set — `--accept-routes`
  goes here; there's no separate declarative "accept routes" option).

### Changes

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

### Manual steps (user, in Tailscale admin console — cannot be scripted)
1. Create a **reusable, non-ephemeral** Tailscale auth key (this box may be rebuilt —
   an ephemeral/one-shot key would strand it). Tag it if the tailnet uses ACL tags.
2. Confirm `proxmox1`'s advertised subnet route is **approved** (separate from any
   client's `--accept-routes` flag — approval is an admin-console action, not visible
   from `tailscale status` CLI output).
3. Hand the raw key value over for the `sops` edit step — never committed in plaintext.

## Part 2 — oauth2-proxy auth gate (GitHub), protecting the test page

Verified against the actual nixpkgs module sources (`services/security/oauth2-proxy.nix`
and `oauth2-proxy-nginx.nix`), not guessed:

- The `services.oauth2-proxy.nginx` integration module auto-wires the entire
  `auth_request`/`/oauth2/` nginx dance for any vhost listed in
  `services.oauth2-proxy.nginx.virtualHosts` — no hand-rolled nginx location blocks
  needed. It merges into our *existing* `hetzner.nixhomelab.de` vhost definition
  cleanly (adds `extraConfig`/new locations; doesn't touch our existing
  `locations."/".root`).
- GitHub provider has typed `org`/`team` restriction options, but no typed "specific
  user" option — the real oauth2-proxy binary supports `--github-user=<name>` via the
  module's open-ended `extraConfig` passthrough (any key becomes `--key=value`).
- `email.domains` must be set (e.g. `[ "*" ]`) or the email-domain gate blocks everyone
  regardless of the GitHub-specific check — the two checks are independent gates, not
  one overriding the other.
- Cookie secret must be a file (`cookie.secretFile`), not inlined.
- I'll set `services.oauth2-proxy.enable = true;` explicitly rather than relying on the
  integration module's auto-enable heuristic (which only triggers on an exact
  `"127.0.0.1:"`-prefixed proxy string, not the real default `"http://127.0.0.1:4180"`).

### Changes to `Maschines/hetzner-nbg1.nix`

```nix
sops.secrets.oauth2_proxy_client_secret = { };
sops.secrets.oauth2_proxy_cookie_secret = { };

services.oauth2-proxy = {
  enable = true;
  provider = "github";
  clientID = "<GitHub OAuth App Client ID>"; # not secret, filled in at execution time
  clientSecretFile = config.sops.secrets."oauth2_proxy_client_secret".path;
  cookie.secretFile = config.sops.secrets."oauth2_proxy_cookie_secret".path;
  email.domains = [ "*" ];
  extraConfig = {
    github-user = "TheZombie1999";
  };
};

services.oauth2-proxy.nginx = {
  domain = "hetzner.nixhomelab.de";
  virtualHosts."hetzner.nixhomelab.de" = { };
};
```

No firewall changes (oauth2-proxy listens on `127.0.0.1:4180` only, proxied by nginx
already on 443).

### Manual steps (user, on GitHub — cannot be scripted)
1. Create a GitHub OAuth App at github.com/settings/developers:
   - Homepage URL: `https://hetzner.nixhomelab.de`
   - Authorization callback URL: `https://hetzner.nixhomelab.de/oauth2/callback`
2. Hand over the **Client ID** (goes straight into the nix file, not secret) and
   **Client Secret** (goes into sops) for the edit/deploy step.
3. Generate a cookie secret locally (e.g. `openssl rand -base64 32`) and add it to sops
   as `oauth2_proxy_cookie_secret` alongside the client secret.

### Secrets to add via `sops Secrets/secrets.yaml` (one edit, same host key as Part 1)
```yaml
hetzner_tailscale_key: <tailscale auth key>
oauth2_proxy_client_secret: <github oauth app client secret>
oauth2_proxy_cookie_secret: <openssl rand -base64 32 output>
```

## Part 3 — SSH bastion through hetzner-nbg1 to nixos-onedev

`nixos-onedev` (the git server LXC) has **no Tailscale config at all** today — it's
only reachable via its Proxmox host's local LXC bridge. To jump to it through
`hetzner-nbg1`, it must join the tailnet first, exactly like Part 1 but for a
different host.

### 3a. Join `nixos-onedev` to the tailnet

Same pattern as Part 1, applied to `Maschines/nixos-onedev.nix` (currently **not** in
the "do not touch" list — only `microstar.nix`/`moab.nix` stay untouched):

- `flake.nix`: add `specialArgs = { inherit inputs; };` to the `"nixos-onedev"`
  `nixosConfigurations` entry (currently has none, same gap as `hetzner-nbg1` had).
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
  key the same way as before — need to confirm this machine can reach it, e.g. via
  `ssh tim@nixos-onedev` as `deploy.nodes.nixos-onedev` already does; if not reachable
  from here, this step runs from wherever that hostname does resolve).
- `Secrets/secrets.yaml`: add `onedev_tailscale_key` (another reusable, non-ephemeral
  Tailscale auth key — same manual admin-console step as Part 1).
- Deploy via the existing `deploy.nodes.nixos-onedev` target: `deploy .#nixos-onedev`.

**Ordering dependency**: `nixos-onedev` must actually join and be assigned a tailnet IP
*before* step 3b below can reference it — `tailscale status` after this deploy reveals
the real address (Tailscale doesn't let you pre-pick it declaratively here).

### 3b. Dedicated restricted "jump" user on `hetzner-nbg1`

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

### Usage
```
ssh -J jump@hetzner.nixhomelab.de tim@<nixos-onedev-tailnet-ip>
```
Works from any machine with the right key, regardless of whether *that* machine is on
the home tailnet at all — solves the "work laptop on a different tailnet" case
directly.

## Deploy

Standard known-quirk invocation for this host (cosmetic `dbus-broker` reload
false-positive, and the unrelated broken `bootstrap` nixosConfiguration tripping
`nix flake check`):
```
deploy .#hetzner-nbg1 --skip-checks --auto-rollback false --magic-rollback false
deploy .#nixos-onedev --skip-checks --auto-rollback false --magic-rollback false
```

## Verification

**Tailscale:**
1. `ssh root@2a01:4f8:1c1c:8a66::1 systemctl status tailscaled tailscaled-autoconnect` — active.
2. `tailscale status` on the box — no `NeedsLogin`, shows tailnet peers.
3. Locally, `tailscale status` now shows `hetzner-nbg1` online.
4. From the box, `ping -c3 100.87.237.46` (proxmox1) — basic peer reachability.
5. Ping an address *inside* proxmox1's advertised home-LAN CIDR (not a tailnet node
   itself) — this is what actually proves route *acceptance*, distinct from #4. If this
   fails but #4 works, suspect the route isn't *approved* server-side (manual step
   above), not a Nix misconfiguration.

**Auth gate:**
6. `curl -6 -I https://hetzner.nixhomelab.de/` unauthenticated → expect a redirect
   (307) toward `/oauth2/start`, not a 200 with the page body.
7. In a real browser, visit the site → redirected to GitHub login → after
   authorizing as `TheZombie1999`, redirected back and the "Hello World" page renders.
8. Log in as a *different* GitHub account (or reason about it without testing) →
   should be rejected — confirms `github-user` restriction is actually narrowing
   access, not just gating on "any GitHub account."
9. `nginx -t` passes; `ss -tlnp` still shows only 22/80/443 listening externally
   (`oauth2-proxy` only on loopback) — confirms no new public attack surface beyond
   the intended auth-gated page.

## Verification — Part 3 (SSH bastion)

10. After 3a deploys, `ssh tim@nixos-onedev tailscale ip -4` (or check the admin
    console) — get the real tailnet IP, confirm it shows as an online peer locally too.
11. After 3b deploys, from a machine that is *not* on the home tailnet:
    `ssh -J jump@hetzner.nixhomelab.de tim@<that-ip>` — should land on `nixos-onedev`.
12. From the same jump key, attempt `ssh jump@hetzner.nixhomelab.de` directly (no `-J`,
    i.e. trying to get a shell on Hetzner itself) — should print the `command=` message
    and disconnect, not grant a shell.
13. Attempt `-J jump@hetzner.nixhomelab.de` toward a *different* tailnet address (e.g.
    `microstar`'s or `proxmox1`'s) — should be refused by `permitopen`, confirming the
    restriction is per-target, not "anything Hetzner can reach."

## Explicitly out of scope
No new `nginx.virtualHosts` for a real backend, no decision yet on which home-lab
*web* service gets proxied next (that's still: add a `virtualHosts."<sub>.nixhomelab.de"`
entry with `proxyPass`, plus list it in `services.oauth2-proxy.nginx.virtualHosts` to
reuse the same login). No changes to `microstar.nix` or `moab.nix`. The Minecraft-style
`nginx stream` TCP-forward pattern stays documented-only, not implemented.

## Documentation deliverable

Split this plan into per-part spec docs in the repo, under a new `Specs/` directory
(matching the existing `Hardware/`/`Maschines/`/`Modules/` PascalCase convention):
- `Specs/01-tailscale-join.md` — Part 1 content (tunnel join, sops/age wiring, route
  acceptance, verification steps 1–5).
- `Specs/02-oauth2-proxy-auth.md` — Part 2 content (GitHub OAuth app, oauth2-proxy
  config, verification steps 6–9).
- `Specs/03-ssh-bastion.md` — Part 3 content (nixos-onedev tailnet join, jump user,
  `permitopen` restriction, verification steps 10–13).

Each doc should stand alone (reader shouldn't need the other two open to follow it),
but can cross-reference the others by filename for context (e.g. "requires Part 1 to
be deployed first"). Write these once implementation is complete and verified, so they
describe what was actually built rather than restating this plan verbatim.

## Critical files
- `/home/tim/OneDev/MyNixosConfiguration/Maschines/hetzner-nbg1.nix`
- `/home/tim/OneDev/MyNixosConfiguration/Maschines/nixos-onedev.nix`
- `/home/tim/OneDev/MyNixosConfiguration/flake.nix`
- `/home/tim/OneDev/MyNixosConfiguration/.sops.yaml`
- `/home/tim/OneDev/MyNixosConfiguration/Secrets/secrets.yaml`
- `/home/tim/OneDev/MyNixosConfiguration/Maschines/moab.nix` (reference only, do not modify)
