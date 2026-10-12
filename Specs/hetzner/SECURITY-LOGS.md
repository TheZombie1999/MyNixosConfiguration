# Checking hetzner-nbg1 for malicious activity

Quick reference for reviewing logs on this box. Written for the config as of
2026-10-12 (sshd VERBOSE logging, persistent journald capped at 1G, fail2ban on the
sshd jail, nginx access/error logs). Run everything below as `root` (or `tim` with
`sudo`).

## 1. Thirty-second triage

```
systemctl --failed                      # anything crashed/failed to start?
fail2ban-client status sshd             # who's currently banned?
journalctl -p warning -b                # warnings+ since last boot, system-wide
last -n 20                              # recent successful interactive logins
```

If `systemctl --failed` is non-empty, or `last` shows a login you don't recognize,
stop and dig in below before assuming it's noise.

## 2. SSH login attempts

sshd runs at `LogLevel VERBOSE` specifically so every attempt is visible, not just
successful ones.

```
journalctl -u sshd -f                          # live tail
journalctl -u sshd --since "1 hour ago"
journalctl -u sshd --since today | grep -i "invalid user\|failed\|refused"
```

What you'll see constantly, and can ignore: `Invalid user <random>`,
`Connection closed by invalid user ... [preauth]`, `banner exchange: ... Connection
reset by peer` — this is internet-background-radiation (bots scanning every public
IPv4/v6 address on port 22). Since auth here is key-only
(`PasswordAuthentication no`), none of this can actually succeed.

What's worth investigating:
- `Accepted publickey for <user>` from an IP/time you don't recognize. Cross-check the
  key fingerprint in the same log line against what's declared in
  `Maschines/hetzner-nbg1.nix` (`users.users.<name>.openssh.authorizedKeys.keys`) —
  only `root` and `tim` should ever appear here, both with the same single
  `sk-ssh-ed25519` resident key.
- Any `Accepted` line for a user other than `root`/`tim` (shouldn't be possible --
  `AllowUsers` is restricted to exactly those two -- but confirm rather than assume).
- A sudden sustained burst of attempts from one source outpacing fail2ban's ban list
  (check with `fail2ban-client status sshd` -- if an IP is hammering and *not* banned,
  something's wrong with fail2ban, not just a scanner).

## 3. fail2ban

```
fail2ban-client status sshd             # currently banned IPs + attempt counts
journalctl -u fail2ban --since today    # ban/unban events
```

Config: `maxretry=4`, `bantime=1h` with exponential backoff
(`bantime-increment.enable`), so repeat offenders get banned longer each time.
`127.0.0.1`, `::1`, and the Tailscale CGNAT range (`100.64.0.0/10`) are
permanently whitelisted and will never show up here.

## 4. Nginx (web) logs

```
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log                 # level: warn (catches TLS/protocol noise too)
grep -v ' 200 \| 304 \| 301 ' /var/log/nginx/access.log | less   # anything that *isn't* a normal hit
awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -rn | head -20  # top requesters
```

Rotated weekly, 26 generations kept (~6 months) automatically -- old logs are
`/var/log/nginx/access.log.1.gz`, `.2.gz`, etc.

What's worth investigating:
- Status codes other than `200`/`301`/`304`/`404` in volume -- especially `401`/`403`
  clusters once the oauth2-proxy auth gate (`Specs/hetzner/02-oauth2-proxy-auth.md`)
  is deployed, since that's where real login-attempt data for the *web* side will
  live (`journalctl -u oauth2-proxy` once it exists).
- Requests for paths that don't exist on this site (`/wp-admin`, `/.env`, `/admin`,
  etc.) -- normal scanner noise, but worth noting if volume spikes.
- Any request method other than `GET`/`HEAD` hitting `/` (there is no POST endpoint
  on the current "Hello World" page).

## 5. System-level integrity spot checks

These don't change often -- if any of them differ from what's declared in
`Maschines/hetzner-nbg1.nix`, something modified the system outside of a deploy.

```
cat /etc/ssh/authorized_keys.d/root /etc/ssh/authorized_keys.d/tim   # should be one key each, identical
awk -F: '$3==0 || $7 !~ /nologin|false/' /etc/passwd                 # should list only root, tim
find /run/wrappers -perm -4000 -type f                               # suid wrappers -- should be the standard NixOS set only
ss -tlnp                                                             # should still be exactly 22/80/443 + loopback
systemctl list-timers --all                                          # should only be fstrim, logrotate, acme-renew, tmpfiles-clean
readlink /run/current-system                                         # compare against what you last deployed
```

## 6. Log retention / disk

```
journalctl --disk-usage          # capped at 1G (services.journald.extraConfig)
du -sh /var/log/nginx/           # capped by weekly rotation, 26 generations
df -h /
```

## Known-safe baseline (so you know what "normal" looks like)

- Constant low-level SSH scan noise on port 22, zero successful auth from unknown
  keys -- expected, not a finding.
- `fail2ban-client status sshd` showing a handful of banned IPs at any given time --
  expected on a box with a public SSH port.
- `last`/`journalctl -u sshd` showing logins from your own current IP(s) -- that's
  you.
- Nothing above should ever show PasswordAuthentication succeeding (it's disabled
  entirely) or a login from a user other than `root`/`tim`.
