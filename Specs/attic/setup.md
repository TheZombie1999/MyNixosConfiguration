# Personal Nix binary cache: Attic on a new `attic` Proxmox LXC

## Context

The user wants a personal Nix binary cache so builds done on any machine in the
fleet (mainly `moab`, the primary desktop) don't get rebuilt from scratch on every
other machine (`nixos-onedev`, `hetzner-nbg1`). **Attic** was chosen over Harmonia
because this fleet builds in multiple independent places — Attic's push model fits
that, Harmonia only passively serves one host's own store. Hosting it was first
planned on the existing `microstar` host, but the user decided instead on a **brand
new dedicated Proxmox LXC**, following the existing `nixos-onedev` LXC as the
pattern to copy. Decisions locked in from this round's questions: hostname **`attic`**,
a **direct Tailscale join** for this new host (its own tailnet IP, independent of any
subnet-route timing), and a **small** LXC (1 vCPU / 1GB RAM / 16GB disk).

Note found along the way, not part of this task: `nixos-onedev.nix` has a full KDE
Plasma6/SDDM desktop block and `services.qemuGuest.enable` that look like
copy-paste leftovers from the generic `Images/bootstrap.nix` installer image (a
desktop environment and a QEMU-specific guest agent make little sense on a headless
LXC, which shares the Proxmox host's kernel rather than running its own). The new
`attic.nix` deliberately omits both rather than propagating what looks like cruft —
flagged here in case the user wants that cleaned up in `nixos-onedev.nix` separately
some other time.

Also found and explicitly deferred (not part of this task, per the user's own
earlier choice when this was still the microstar plan): `Modules/ansible-pull.nix` is
fully commented out and breaks `nixosConfigurations.microstar`'s evaluation. Unrelated
to this plan now that microstar isn't involved, but still a real, pre-existing bug in
the repo worth fixing eventually.

## Established patterns being reused (verified in-repo, not guessed)

- **LXC creation pipeline** (`justfile`): `just build-bootstrap-image` runs
  `nixos-rebuild build-image --flake .#bootstrap --image-variant proxmox-lxc` using
  the generic `Images/bootstrap.nix`; `just upload-bootstrap-image` scps the resulting
  tarball to `root@proxmox.local:/var/lib/vz/template/cache/`. This is how new LXC
  templates get onto the Proxmox host; actually instantiating a container from that
  template (`pct create` or the Proxmox UI, picking an ID/resources) is a manual,
  Proxmox-console step outside this flake, same as every other "can't be scripted"
  step already documented elsewhere in `Specs/hetzner/`.
- **LXC host-config pattern** (`Maschines/nixos-onedev.nix`): no separate
  `Hardware/*.nix` file needed — `imports = [ (modulesPath + "/virtualisation/proxmox-lxc.nix") ];`
  is enough, since an LXC shares the Proxmox host's kernel. It also already does
  `PermitRootLogin = "no"` and clears `users.users.root.openssh.authorizedKeys.keys`
  — the no-root-SSH pattern established for `hetzner-nbg1` this session already
  exists natively here; nothing new to invent.
- **deploy-rs node pattern**: `nixos-onedev`'s entry already uses
  `user = "root"; sshUser = "tim";` (tim connects, sudo-escalates for activation) —
  exactly the pattern `hetzner-nbg1` was switched to this session. Mirror it directly.
- **Tailscale join pattern** (from `Specs/hetzner/01-tailscale-join.md` /
  `03-ssh-bastion.md`'s already-planned-but-not-yet-deployed nixos-onedev join):
  `sops.secrets.<host>_tailscale_key`, `services.tailscale.enable = true;` +
  `authKeyFile = config.sops.secrets."<host>_tailscale_key".path;`. No
  `useRoutingFeatures`/`extraUpFlags` needed — this host only needs to *be*
  reachable, not accept routes to other subnets.
- **sops age-key pattern for disposable/rebuildable hosts** (`hetzner-nbg1`, planned
  `nixos-onedev`): `sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];` —
  derives the age recipient from the host's own SSH host key rather than a
  manually-placed `keys.txt`.

## Phase 0 — Provision the LXC (manual, Proxmox console — cannot be scripted)

1. Confirm the bootstrap image template is current on the Proxmox host; if stale or
   missing, `just build-bootstrap-image` then `just upload-bootstrap-image`.
2. Create a new LXC container from that template: hostname `attic`, 1 vCPU, 1GB RAM,
   16GB disk, on the same network bridge as the rest of the home-lab (same as
   `nixos-onedev`).
3. Boot it, confirm SSH reachability over the LAN as `tim` using the existing
   `sk-ssh-ed25519` resident key (the bootstrap image already provisions this user/key
   — same key used everywhere else in this fleet).

## Phase 1 — Wire `attic` into the flake + join the tailnet

1. From this container's actual SSH host key (`ssh-keyscan`/direct read of
   `/etc/ssh/ssh_host_ed25519_key.pub`), derive its age pubkey via `ssh-to-age`.
2. `.sops.yaml`: add a new `&attic` anchor with that age pubkey, add it to the
   existing single key group for `Secrets/secrets\.yaml$`.
3. Create `Maschines/attic.nix`:
   ```nix
   { pkgs, config, inputs, modulesPath, ... }:
   {
     imports = [
       (modulesPath + "/virtualisation/proxmox-lxc.nix")
       inputs.sops-nix.nixosModules.sops
     ];

     networking.hostName = "attic";

     sops.defaultSopsFile = ../Secrets/secrets.yaml;
     sops.defaultSopsFormat = "yaml";
     sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
     sops.secrets.attic_tailscale_key = { };

     services.tailscale = {
       enable = true;
       authKeyFile = config.sops.secrets."attic_tailscale_key".path;
     };

     services.openssh = {
       enable = true;
       settings = {
         PasswordAuthentication = false;
         KbdInteractiveAuthentication = false;
         PermitRootLogin = "no";
       };
     };
     users.users.root.openssh.authorizedKeys.keys = [ ];

     users.users.tim = {
       isNormalUser = true;
       extraGroups = [ "wheel" ];
       openssh.authorizedKeys.keys = [
         "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIK5ynhdh9jUSrKGll4ZOw4Krji+ipGNfsFKu6EmbEpVMAAAABHNzaDo="
       ];
     };
     security.sudo.wheelNeedsPassword = false;

     networking.firewall.allowedTCPPorts = [ 22 ];

     nix.settings = {
       experimental-features = [ "nix-command" "flakes" ];
       trusted-users = [ "root" "@wheel" ];
     };

     environment.systemPackages = with pkgs; [ helix git curl ];

     system.stateVersion = "25.11";
   }
   ```
4. `flake.nix`: add alongside the other `nixosConfigurations`:
   ```nix
   "attic" = nixpkgs.lib.nixosSystem {
     system = "x86_64-linux";
     specialArgs = { inherit inputs; };
     modules = [ ./Maschines/attic.nix ];
   };
   ```
   and a deploy-rs node:
   ```nix
   deploy.nodes.attic = {
     hostname = "attic"; # or its LAN IP/hostname, resolvable before tailscale is up
     profiles.system = {
       user = "root";
       path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."attic";
       sshUser = "tim";
     };
   };
   ```
5. Manual (Tailscale admin console): create a reusable, non-ephemeral auth key for
   this host (ephemeral would strand it on rebuild).
6. `sops Secrets/secrets.yaml`: add `attic_tailscale_key: <the key>`. Follow with
   `sops updatekeys Secrets/secrets.yaml`.
7. Deploy: `deploy .#attic` (first deploy happens over the LAN address, before
   Tailscale is active on this host — fine, SSH as `tim` already works from the
   bootstrap image).
8. Verify: `tailscale status` (run elsewhere on the tailnet) shows `attic` online;
   `ssh tim@attic` still works; `sudo -n true` succeeds for `tim`.

## Phase 2 — Attic server config

Verified against the real `services.atticd` nixpkgs module (present natively,
`nixos-26.05`/unstable — no new flake input needed) and Attic's own
`config-template.toml`. Defaults already do what's wanted (local filesystem storage,
sqlite db) — no need to override `storage`/`database`.

Add to `Maschines/attic.nix`:
```nix
sops.secrets.attic_environment_file = { };

services.atticd = {
  enable = true;
  environmentFile = config.sops.secrets."attic_environment_file".path;
  settings = {
    listen = "[::]:8080";
    jwt = { };
    chunking = {
      nar-size-threshold = 65536;
      min-size = 16384;
      avg-size = 65536;
      max-size = 262144;
    };
  };
};

environment.systemPackages = with pkgs; [ helix git curl attic-client ];
```

Firewall: restrict the cache port to the tailnet only, rather than the broader LAN —
unlike `microstar`'s existing "firewall disabled entirely" convention, this is a
brand-new host with no such precedent to match, so do it properly:
```nix
networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 8080 ];
```
(leave the plain `networking.firewall.allowedTCPPorts = [ 22 ]` from Phase 1 as-is —
SSH stays reachable on the LAN for management/deploy-rs; the cache HTTP port does not).

**The secret**: `services.atticd.environmentFile` needs a plain `KEY=value`-style
`EnvironmentFile`. No `sops.templates` needed (not used anywhere else in this repo,
and there's only one variable) — the sops secret's entire decrypted content is simply
the finished `KEY="value"` line, which is already valid `EnvironmentFile=` syntax
as-is.
1. Generate it: `nix run nixpkgs#openssl -- genrsa -traditional 4096 | base64 -w0`
2. `sops Secrets/secrets.yaml`, add:
   ```yaml
   attic_environment_file: |
     ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64="<base64 output from step 1>"
   ```

Deploy: `deploy .#attic` again. Verify: `systemctl status atticd` active,
`journalctl -u atticd` clean.

## Phase 3 — Bootstrap the cache (one-time, imperative — not expressible in Nix)

Attic uses "managed signing": the signing keypair is generated server-side at
cache-creation time and lives in atticd's own database, not the Nix store — no
declarative `secretKeyFile`-style option exists (confirmed against Attic's own
docs/source). Run on `attic` as `tim`, once `atticd` is confirmed active:

1. `atticd-atticadm make-token --sub admin --validity '10y' --pull '*' --push '*' --create-cache '*' --delete '*'`
   (the module-provided wrapper already loads the RS256 secret from the environment
   file — no manual sourcing needed)
2. `attic login attic http://localhost:8080 <admin-token>`
3. `attic cache create homelab`
4. `attic cache configure homelab --public` — see rationale below
5. `attic cache info homelab` → copy the `Public Key: homelab:<base64>=` line; every
   client needs this in `trusted-public-keys`.

**Public vs. private**: go public. Attic's managed signing always signs NAR responses
server-side regardless, so a public cache can't be used to inject unsigned/forged
content — `trusted-public-keys` protects clients either way. The only thing public
gives up is confidentiality of which store paths exist, a negligible exposure for
ordinary NixOS closures on an internal, tailnet-only cache, and it avoids
distributing a pull-netrc to every client.

Sanity check once public: `curl http://localhost:8080/homelab/nix-cache-info` returns
cache info with no auth error.

## Phase 4 — Client configuration

**`Maschines/nixos-onedev.nix`** (no in-flight local changes — safe to edit
directly). Extend its existing `nix.settings` block:
```nix
nix.settings = {
  experimental-features = [ "nix-command" "flakes" ];
  trusted-users = [ "root" "@wheel" ];
  substituters = [ "http://attic:8080/homelab" ];
  trusted-public-keys = [ "homelab:<base64-from-attic-cache-info>" ];
};
```

**`Maschines/hetzner-nbg1.nix`** (has in-flight uncommitted changes from this
session's SSH-hardening work — still safe to append the same two lines to its
existing `nix.settings` block, as a clearly separate addition). This host isn't
Tailscale-joined yet (`01-tailscale-join.md` is planned, not deployed) —
configuring the substituter now anyway is deliberate: an unreachable substituter just
times out and falls through to `cache.nixos.org`, so this is a no-op today and "just
works" the moment Tailscale join lands later, at zero cost now.

**`moab`**: do **not** edit `Maschines/moab.nix` (per standing project rule — another
session owns its in-flight changes). Document these two lines for the user to add by
hand once Attic is confirmed working:
```nix
nix.settings.substituters = [ "http://attic:8080/homelab" ];
nix.settings.trusted-public-keys = [ "homelab:<base64-from-attic-cache-info>" ];
```
(`attic` resolves via Tailscale MagicDNS since moab is already tailnet-joined; use
its Tailscale IP from `tailscale status` instead if MagicDNS isn't enabled.)

**`lenovo`, `wsl`**: skip — dormant/ephemeral, not worth wiring up.

## Phase 5 — Push workflow (moab → cache)

Recommendation: plain manual `attic push`, not a `post-build-hook` — a hook would
require editing `moab.nix` (root's build-time credentials), a bigger, riskier change
than needed here, and conflicts with the "don't touch moab.nix" constraint. Manual
CLI login needs zero file edits:
```
# on attic: atticd-atticadm make-token --sub moab --validity '5y' --push homelab --pull homelab
# on moab:
nix shell nixpkgs#attic-client --command attic login homelab http://attic:8080 <moab-token>
```

Add a small justfile recipe (the justfile is a repo convenience script, not a
machine's Nix config — safe to add without touching `moab.nix`):
```just
# Push moab's current system closure to the homelab attic cache
push-cache cache="homelab" target="/run/current-system":
    nix shell nixpkgs#attic-client --command attic push {{cache}} {{target}}
```

Automating further via `nix.settings.post-build-hook` is a valid future upgrade, not
designed now.

## Verification (end to end)

1. `nix eval .#nixosConfigurations.attic.config.system.build.toplevel.drvPath` builds
   cleanly before first deploy.
2. After Phase 1 deploy: `tailscale status` shows `attic` online; SSH as `tim` works;
   `sudo -n true` succeeds.
3. After Phase 2 deploy: `systemctl status atticd` active; `journalctl -u atticd`
   clean; `curl http://localhost:8080/homelab/nix-cache-info` (after Phase 3) returns
   cache info with no auth error.
4. On moab: `just push-cache` (or `attic push homelab /run/current-system` directly) —
   confirm server-side via `attic cache info homelab` (object count increases) or
   `curl http://attic:8080/homelab/<hash>.narinfo`.
5. Deploy the client config to `nixos-onedev` (`deploy -s .#nixos-onedev`, existing
   recipe) once it has Tailscale connectivity; trigger a rebuild of something already
   pushed with `-vv` and confirm the log shows
   `copying path '/nix/store/...' from 'http://attic:8080/homelab'` instead of a full
   local build or a pull from `cache.nixos.org`, with no signature-mismatch warnings.
6. From hetzner-nbg1 or moab: `ss -tlnp`/`ip a` style check confirms `attic`'s port
   8080 is NOT reachable from the plain LAN, only via its tailnet address — confirms
   the `tailscale0`-scoped firewall rule is actually restricting exposure as intended.

## Critical files

- `/home/tim/OneDev/MyNixosConfiguration/Maschines/attic.nix` (new)
- `/home/tim/OneDev/MyNixosConfiguration/flake.nix`
- `/home/tim/OneDev/MyNixosConfiguration/.sops.yaml`
- `/home/tim/OneDev/MyNixosConfiguration/Secrets/secrets.yaml`
- `/home/tim/OneDev/MyNixosConfiguration/Maschines/nixos-onedev.nix`
- `/home/tim/OneDev/MyNixosConfiguration/Maschines/hetzner-nbg1.nix`
- `/home/tim/OneDev/MyNixosConfiguration/justfile`
- `/home/tim/OneDev/MyNixosConfiguration/Maschines/moab.nix` (document only, do not edit)
- `/home/tim/OneDev/MyNixosConfiguration/Maschines/nixos-onedev.nix` (reference pattern for the LXC/SSH/deploy-rs shape)
