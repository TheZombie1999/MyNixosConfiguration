# Task 6 — Expose Homer publicly on homer.nixhomelab.de, behind GitHub login

## Goal

Make Homer (a dashboard app running unmanaged in a Proxmox LXC on the home LAN,
`192.168.178.46:8010`, plain Debian, python3 http server) reachable from the public
internet via `hetzner-nbg1`, on `homer.nixhomelab.de`, gated behind GitHub OAuth
login restricted to `TheZombie1999` only — since Homer likely links to other
internal services and shouldn't be wide open.

This is also the first real deployment of `oauth2-proxy`
([02-oauth2-proxy-auth.md](./02-oauth2-proxy-auth.md) researched it but it was
never actually deployed).

## Current state

- `hetzner-nbg1` already reaches Homer today: `curl http://192.168.178.46:8010/`
  run *from* `hetzner-nbg1` returns HTTP 200, over the Tailscale-accepted
  `192.168.178.0/24` subnet route already live since
  [01-tailscale-join.md](./01-tailscale-join.md). No new routing/Tailscale work
  needed.
- DNS for `homer.nixhomelab.de` already resolves to both `2.31.59.138` (A) and
  `2a01:4f8:1c1c:8a66::1` (AAAA) — both point at `hetzner-nbg1`. Already done.
- `oauth2-proxy` has never been deployed anywhere in this repo (no systemd unit on
  the live host before this task).
- `hetzner.nixhomelab.de` (the existing "Hello World" page) deliberately stays
  public/ungated in this task, to keep scope minimal on this first oauth2-proxy
  rollout — not a limitation of the module, a scope choice.
- Homer itself remains an unmanaged, unmonitored plain-Debian LXC — out of scope
  here, this task only makes it reachable and gated.

## Research findings (verified against nixpkgs source, not guessed)

Checked directly against the pinned nixpkgs revision in this flake's `flake.lock`
(`nixos/modules/services/security/oauth2-proxy.nix` +
`oauth2-proxy-nginx.nix`):

- oauth2-proxy is a **single** systemd instance/config — one GitHub OAuth App, one
  `github-user` restriction, automatically covers every protected vhost. There's
  no way to run "two separate logins" even if wanted.
- `/oauth2/start` and `/oauth2/callback` are served **only** on
  `services.oauth2-proxy.nginx.domain` (kept as `hetzner.nixhomelab.de` here), not
  on each protected vhost. Every gated vhost's 401 redirects there. So the GitHub
  OAuth App needs exactly **one** callback URL, regardless of how many vhosts end
  up in `virtualHosts`.
- Because the login/cookie-setting round-trip happens on `hetzner.nixhomelab.de`
  but needs to authenticate requests to `homer.nixhomelab.de`, the auth cookie
  must be scoped to the shared parent domain via
  `services.oauth2-proxy.cookie.domain = ".nixhomelab.de";` — without this the
  cookie set on `hetzner.nixhomelab.de` would never be sent back on requests to
  `homer.nixhomelab.de`, causing an infinite GitHub-login redirect loop on Homer
  even though the user is "logged in."
- `recommendedProxySettings` (`proxy_set_header Host`/`X-Forwarded-*` etc.) is
  auto-force-enabled globally by the oauth2-proxy nginx module the moment
  `services.oauth2-proxy.nginx.virtualHosts != {}` — no manual header plumbing
  needed on the Homer `proxyPass` location.

## Changes

**`Maschines/hetzner-nbg1.nix`**:

```nix
sops.secrets.oauth2_proxy_client_secret = { };
sops.secrets.oauth2_proxy_cookie_secret = { };

services.oauth2-proxy = {
  enable = true;
  provider = "github";
  clientID = "<GitHub OAuth App Client ID>"; # not secret, filled in at execution time
  clientSecretFile = config.sops.secrets."oauth2_proxy_client_secret".path;
  cookie = {
    secretFile = config.sops.secrets."oauth2_proxy_cookie_secret".path;
    domain = ".nixhomelab.de";
  };
  email.domains = [ "*" ];
  extraConfig = {
    github-user = "TheZombie1999";
  };
};

services.oauth2-proxy.nginx = {
  domain = "hetzner.nixhomelab.de";
  virtualHosts."homer.nixhomelab.de" = { };
};
```

Plus a new nginx vhost, sibling of the existing `hetzner.nixhomelab.de` one:

```nix
virtualHosts."homer.nixhomelab.de" = {
  enableACME = true;
  forceSSL = true;
  extraConfig = ''
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "DENY" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
  '';
  locations."/".proxyPass = "http://192.168.178.46:8010";
};
```

No changes needed to `flake.nix`, `.sops.yaml`, or
`networking.firewall.allowedTCPPorts` — oauth2-proxy listens on `127.0.0.1:4180`
only; the connection to Homer is outbound over the already-accepted subnet route,
not a new listening port.

## Manual steps (user, in order)

1. ~~DNS record~~ — already done.
2. Create a GitHub OAuth App at github.com/settings/developers (none existed
   before this task):
   - Homepage URL: `https://hetzner.nixhomelab.de`
   - Authorization callback URL: `https://hetzner.nixhomelab.de/oauth2/callback`
     (single callback — do not add a second one for `homer.nixhomelab.de`).
   - Hand over the Client ID (goes into the Nix file, not secret) and Client
     Secret (goes into sops).
3. Generate a cookie secret: `openssl rand -base64 32`.

## Secrets added via `sops Secrets/secrets.yaml`

```yaml
oauth2_proxy_client_secret: <github oauth app client secret>
oauth2_proxy_cookie_secret: <openssl rand -base64 32 output>
```

## Deploy

```
nix develop -c deploy .#hetzner-nbg1 --skip-checks --auto-rollback false --magic-rollback false
```
(or `just deploy-hetzner-nbg1`)

## Verification

1. `curl -I https://homer.nixhomelab.de/` unauthenticated → expect a `307` toward
   `https://hetzner.nixhomelab.de/oauth2/start?...`, not a `200` with Homer's HTML.
2. In a real browser: visit `https://homer.nixhomelab.de` → redirected to
   `hetzner.nixhomelab.de/oauth2/start` → GitHub login as `TheZombie1999` →
   redirected back and the dashboard actually renders on `homer.nixhomelab.de`
   (validates the `cookie.domain` fix specifically, not just "login works").
3. Inspect the `Set-Cookie` response in devtools after step 2 → confirm
   `Domain=nixhomelab.de` or `Domain=.nixhomelab.de` (not host-only).
4. A different GitHub account is rejected by the `github-user` restriction.
5. `https://hetzner.nixhomelab.de/` still returns its existing public `200` Hello
   World page directly — confirms no scope creep onto the existing vhost.
6. `nginx -t` passes; `ss -tlnp` still shows only `22/80/443` listening externally
   plus `oauth2-proxy` on `127.0.0.1:4180` only — no new public port.
7. `curl http://192.168.178.46:8010/` from `hetzner-nbg1` still returns `200`.

## Risks / things to watch

- A missing/wrong DNS record at deploy time could make the new vhost's ACME
  HTTP-01 challenge fail in a way that risks the single shared `nginx.service`
  unit failing to (re)start, taking the already-working `hetzner.nixhomelab.de`
  down with it. DNS was confirmed correct before this deploy.
- The `cookie.domain` cross-subdomain behavior is inferred from the NixOS
  module's own doc-comment plus general cookie-spec knowledge, not from reading
  oauth2-proxy's Go source directly — verification steps 2/3 confirm this
  empirically on first real login rather than trusting it blindly.
- Homer itself remains unmanaged/unmonitored by NixOS — availability and updates
  of the LXC itself are not covered here.

## Out of scope

Protecting `hetzner.nixhomelab.de` itself, managing Homer's LXC declaratively, any
other home-lab HTTP service.

## Critical files

- `Maschines/hetzner-nbg1.nix`
- `Secrets/secrets.yaml`
- `Specs/hetzner/02-oauth2-proxy-auth.md` (reference — prior research this builds on)
