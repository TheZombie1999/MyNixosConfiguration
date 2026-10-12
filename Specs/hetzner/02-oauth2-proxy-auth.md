# Task 2 — oauth2-proxy auth gate (GitHub), protecting the test page

## Goal

Put `oauth2-proxy` in front of nginx on `hetzner-nbg1`, authenticating against
**GitHub**, restricted to the user's own GitHub account only (not org-wide, not "any
GitHub user"). The existing "Hello World" page on `https://hetzner.nixhomelab.de`
becomes the one concrete, end-to-end test of the whole web-auth chain (DNS → TLS →
GitHub login → page content) — not a real service.

This task is independent of [01-tailscale-join.md](./01-tailscale-join.md) (oauth2-proxy
doesn't touch the tailnet), but shares the same host file
(`Maschines/hetzner-nbg1.nix`) — do both before redeploying, or expect two separate
deploys of the same host.

**Explicitly out of scope for this round**: no real home-lab HTTP backend gets
proxied yet. The Minecraft/`nginx stream`-block TCP-forwarding pattern discussed for
non-HTTP services is documented as a future pattern, not implemented.

## Current state (verified against nixpkgs module sources)

Verified against the actual nixpkgs module sources (`services/security/oauth2-proxy.nix`
and `oauth2-proxy-nginx.nix`), not guessed:

- The `services.oauth2-proxy.nginx` integration module auto-wires the entire
  `auth_request`/`/oauth2/` nginx dance for any vhost listed in
  `services.oauth2-proxy.nginx.virtualHosts` — no hand-rolled nginx location blocks
  needed. It merges into the *existing* `hetzner.nixhomelab.de` vhost definition
  cleanly (adds `extraConfig`/new locations; doesn't touch the existing
  `locations."/".root`).
- GitHub provider has typed `org`/`team` restriction options, but no typed "specific
  user" option — the real oauth2-proxy binary supports `--github-user=<name>` via the
  module's open-ended `extraConfig` passthrough (any key becomes `--key=value`).
- `email.domains` must be set (e.g. `[ "*" ]`) or the email-domain gate blocks everyone
  regardless of the GitHub-specific check — the two checks are independent gates, not
  one overriding the other.
- Cookie secret must be a file (`cookie.secretFile`), not inlined.
- Set `services.oauth2-proxy.enable = true;` explicitly rather than relying on the
  integration module's auto-enable heuristic (which only triggers on an exact
  `"127.0.0.1:"`-prefixed proxy string, not the real default `"http://127.0.0.1:4180"`).

## Changes to `Maschines/hetzner-nbg1.nix`

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

If [01-tailscale-join.md](./01-tailscale-join.md) was already applied, the
`sops.defaultSopsFile`/`sops.defaultSopsFormat`/`sops.age.sshKeyPaths` lines and the
`inputs.sops-nix.nixosModules.sops` import already exist — just add the two new
`sops.secrets.*` entries and the `services.oauth2-proxy*` blocks above. If this task is
applied first, those sops bootstrap lines need adding too (see Task 1 for the exact
block).

No firewall changes needed — oauth2-proxy listens on `127.0.0.1:4180` only, proxied by
nginx already on 443.

## Manual steps (user, on GitHub — cannot be scripted)

1. Create a GitHub OAuth App at github.com/settings/developers:
   - Homepage URL: `https://hetzner.nixhomelab.de`
   - Authorization callback URL: `https://hetzner.nixhomelab.de/oauth2/callback`
2. Hand over the **Client ID** (goes straight into the nix file, not secret) and
   **Client Secret** (goes into sops) for the edit/deploy step.
3. Generate a cookie secret locally (e.g. `openssl rand -base64 32`) and add it to sops
   as `oauth2_proxy_cookie_secret` alongside the client secret.

## Secrets to add via `sops Secrets/secrets.yaml`

```yaml
oauth2_proxy_client_secret: <github oauth app client secret>
oauth2_proxy_cookie_secret: <openssl rand -base64 32 output>
```
Same host key as Task 1 — one edit covers both tasks' secrets if done together.

## Deploy

```
deploy .#hetzner-nbg1 --skip-checks --auto-rollback false --magic-rollback false
```
(`--skip-checks` needed because of a cosmetic `dbus-broker` reload false-positive on
this host, and an unrelated broken `bootstrap` nixosConfiguration tripping `nix flake
check`.)

## Verification

1. `curl -6 -I https://hetzner.nixhomelab.de/` unauthenticated → expect a redirect
   (307) toward `/oauth2/start`, not a 200 with the page body.
2. In a real browser, visit the site → redirected to GitHub login → after
   authorizing as `TheZombie1999`, redirected back and the "Hello World" page renders.
3. Log in as a *different* GitHub account (or reason about it without testing) →
   should be rejected — confirms `github-user` restriction is actually narrowing
   access, not just gating on "any GitHub account."
4. `nginx -t` passes; `ss -tlnp` still shows only 22/80/443 listening externally
   (`oauth2-proxy` only on loopback) — confirms no new public attack surface beyond
   the intended auth-gated page.

## Out of scope here

No new `nginx.virtualHosts` for a real backend, no decision yet on which home-lab
*web* service gets proxied next (that would be: add a
`virtualHosts."<sub>.nixhomelab.de"` entry with `proxyPass`, plus list it in
`services.oauth2-proxy.nginx.virtualHosts` to reuse the same login). The
Minecraft-style `nginx stream` TCP-forward pattern stays documented-only, not
implemented.

## Critical files

- `/home/tim/OneDev/MyNixosConfiguration/Maschines/hetzner-nbg1.nix`
- `/home/tim/OneDev/MyNixosConfiguration/Secrets/secrets.yaml`
