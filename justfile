
# Rebuild nixos system
moab-rebuild: moab-deploy-age-key
    sudo nixos-rebuild switch --flake .#moab

moab-rebuild-after-reboot: moab-deploy-age-key
    sudo nixos-rebuild boot --flake .#moab

# Install sops key
moab-deploy-age-key:
    [ -f ~/.config/sops/age/keys.txt ] || op read "op://Personal/Sops-Nix age key/keys.txt" > ~/.config/sops/age/keys.txt

# Back up moab's SSH host ed25519 key to 1Password
moab-backup-host-key:
    sudo cat /etc/ssh/ssh_host_ed25519_key | op document create - --title "moab ssh_host_ed25519_key" --vault "Personal"
    cat /etc/ssh/ssh_host_ed25519_key.pub | op document create - --title "moab ssh_host_ed25519_key.pub" --vault "Personal"

# Restore moab's SSH host ed25519 key from 1Password (run before sops can decrypt secrets)
moab-restore-host-key:
    op document get "moab ssh_host_ed25519_key" | sudo tee /etc/ssh/ssh_host_ed25519_key > /dev/null
    sudo chmod 600 /etc/ssh/ssh_host_ed25519_key
    op document get "moab ssh_host_ed25519_key.pub" | sudo tee /etc/ssh/ssh_host_ed25519_key.pub > /dev/null
    sudo chmod 644 /etc/ssh/ssh_host_ed25519_key.pub

# Load resident keys from a FIDO authenticator.
load-fidokey-from-yubikey:
    ssh-add -K

# Create a new fido key on a yubikey
generate-fido-key:
    ssh-keygen -t ed25519-sk -O resident

# open secrests.yaml in hx
edit-secrets:
    sops edit ./Secrets/secrets.yaml

# Build a Minimal bootstrap image
build-bootstrap-image:
    nixos-rebuild build-image --flake .#bootstrap --image-variant proxmox-lxc

# Build a bootstrap ISO (bootable installer/live image)
build-bootstrap-iso:
    nixos-rebuild build-image --flake .#bootstrap-iso --image-variant iso

push:
    git push && git push github master

# Check incoming changes from all remotes without pulling
fetch-preview:
    git fetch --all
    @echo "=== origin ===" && git log HEAD..origin/master --oneline
    @echo "=== github ===" && git log HEAD..github/master --oneline

# Upload the built bootstrap LXC image to Proxmox
upload-bootstrap-image:
    scp ./result/tarball/nixos-image-lxc-proxmox-*.tar.xz root@proxmox.local:/var/lib/vz/template/cache/

deploy-nixos-onedev:
    deploy -s .#nixos-onedev

deploy-microstar:
    deploy -s .#microstar

# Remote-install microstar from scratch over SSH: partitions/formats disks via
# disko and installs NixOS, kexec'ing the still-running Proxmox host straight
# into the installer (see Tasks/proxmox-to-nixos-migration.md). Wipes the
# target's disks -- root@192.168.178.100 must already be reachable.
install-microstar target_host="root@192.168.178.100":
    nix run github:nix-community/nixos-anywhere -- --flake .#microstar --target-host {{ target_host }}

# --skip-checks: nix flake check fails on the unrelated broken bootstrap config
# (see Specs/hetzner/01-tailscale-join.md). No rollback -- auto/magic-rollback
# both need a second SSH round-trip from the deploying machine, which this
# 1GB-RAM box with no stable outbound reachability can't rely on.
deploy-hetzner-nbg1:
    nix develop -c deploy .#hetzner-nbg1 --skip-checks --auto-rollback false --magic-rollback false

clean:
    sudo nix-collect-garbage -d
    nix-collect-garbage -d

update-local:
    nix flake update finazebro
    nix flake update onedev
