
# Backup

The onedev pihole nixos-onedev and homer lxc container need to backedup localy.

# Switch to nixos

Use nixos infect on the proxmox machine.

This requires a nixos configuration checked into this repo,
that has an ssh server that acceppts the same ssh keys as the hetzner server
added to the authorized hosts.

Sudo does not need a password on this server.

The disk layout should be keept the same as on the proxmox machine.

No gui should be active or running, the server should be headless after the migration.

Delete the current microstar configuration and recreate it for the new server,
as it should be renamed to microstar.


# Create the server config

Incus should be used instead of lxc.
The sever should run jorgejo.
Podman should also be installed.

# Convert the lxc container to incus

The lxc container should be conveted to incus, after that the need to be started again.
