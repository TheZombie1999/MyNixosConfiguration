
# Rebuild nixos system
moab-rebuild: moab-deploy-age-key
    sudo nixos-rebuild switch --flake .#moab

# Install sops key
moab-deploy-age-key:
    op read "op://Personal/Sops-Nix age key/keys.txt" > ~/.config/sops/age/keys.txt

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

push:
    git push && git push github master
