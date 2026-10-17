{
  pkgs,
  config,
  inputs,
  ...
}:
{
  imports = [
    ./../Hardware/microstar-hardware-configuration.nix
    ./microstar-disko.nix
    inputs.sops-nix.nixosModules.sops
  ];

  networking.hostName = "microstar";
  # Required for ZFS; must be unique per machine, generated once at authoring time.
  networking.hostId = "bcd5badf";

  sops.defaultSopsFile = ../Secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  # Disposable-host pattern, same as hetzner-nbg1/attic: age identity derived
  # from the host's own SSH host key rather than a manually placed keyfile.
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  # Forgejo Actions runner registration secret (UUID + Token pair from
  # Site Administration -> Actions -> Runners -> Create new Runner). The
  # UUID isn't sensitive and lives inline below; only the token is sopsed.
  sops.secrets.microstar_forgejo_runner_token = { };

  # Root lives on its own disk (sdb, ext4 -- see microstar-disko.nix), not on
  # the ZFS mirror, so plain systemd-boot off sdb's ESP is enough; no GRUB/ZFS
  # boot support needed. Firmware is UEFI-capable (confirmed via efibootmgr).
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Reproduces the live Proxmox host's vmbr0 bridge (static 192.168.178.100/24
  # over physical NIC enp3s0, PCI 0000:03:00.0) -- Incus containers get bridged
  # NICs on the same br0 in Phase 4/5 so they keep real LAN IPs.
  networking.useDHCP = false;
  networking.bridges.br0.interfaces = [ "enp3s0" ];
  networking.interfaces.br0.ipv4.addresses = [
    {
      address = "192.168.178.100";
      prefixLength = 24;
    }
  ];
  networking.defaultGateway = "192.168.178.1";
  networking.nameservers = [
    "192.168.178.44" # pihole, once its Incus container is back up
    "1.1.1.1"
  ];

  services.openssh = {
    enable = true;
    authorizedKeysInHomedir = false;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      X11Forwarding = false;
      AllowTcpForwarding = false;
      AllowAgentForwarding = false;
      AllowUsers = [ "tim" ];
      MaxAuthTries = 3;
      LoginGraceTime = 20;
      ClientAliveInterval = 300;
      ClientAliveCountMax = 2;
      LogLevel = "VERBOSE";
    };
  };

  users.users.root.linger = true;
  users.users.tim = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "incus-admin"
      "podman"
    ];
    linger = true;
    openssh.authorizedKeys.keys = [
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIK5ynhdh9jUSrKGll4ZOw4Krji+ipGNfsFKu6EmbEpVMAAAABHNzaDo="
      # CI key for the "deploy every system" Forgejo Actions workflow -- this
      # runner deploys microstar to itself over loopback. See
      # .forgejo/workflows/deploy.yml.
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOPjX9oBHTd5I1ojCjHpAoh/hZ1ivmA453VtcCYfZGWC forgejo-ci@microstar"
    ];
  };

  security.sudo.wheelNeedsPassword = false;
  security.sudo.execWheelOnly = true;
  users.users.root.hashedPassword = "!";

  networking.nftables.enable = true;

  # Required for the rpool mirror (microstar-disko.nix) that Incus's "default"
  # storage pool sits on. Not detectable by nixos-generate-config: the pool
  # can't be mounted/scanned until ZFS support is already enabled.
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.extraPools = [ "rpool" ];
  # Root is ext4 on sda (microstar-disko.nix), not ZFS -- this just silences
  # the forceImportRoot warning, it has no effect here.
  boot.zfs.forceImportRoot = false;

  # Forgejo's repos/DB/etc live on the mirrored rpool instead of sda's plain
  # ext4, so they survive a single-disk failure. Ordered before forgejo.service
  # for free: it's a normal fileSystems entry, so local-fs.target (which
  # forgejo.service depends on via the default systemd unit dependencies)
  # already waits for it to mount.
  fileSystems."/var/lib/forgejo" = {
    device = "rpool/forgejo";
    fsType = "zfs";
  };

  virtualisation.incus = {
    enable = true;
    preseed = {
      # No "networks" block: br0 is a host-level bridge already created by
      # networking.bridges.br0 above, not an Incus-managed network. Declaring
      # it here made Incus try to own/reconcile a network object of the same
      # name as the existing interface, which failed with "Network not
      # found" on every reconciliation after the first. The eth0 profile
      # device below attaches straight to the host bridge via
      # nictype=bridged + parent=br0, which needs no Incus-managed network.
      storage_pools = [
        {
          name = "default";
          driver = "zfs";
          config.source = "rpool/incus";
        }
      ];
      profiles = [
        {
          name = "default";
          devices = {
            root = {
              path = "/";
              pool = "default";
              type = "disk";
            };
            eth0 = {
              name = "eth0";
              nictype = "bridged";
              parent = "br0";
              type = "nic";
            };
          };
        }
      ];
    };
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  services.forgejo = {
    enable = true;
    database.type = "sqlite3";
    settings = {
      server = {
        DOMAIN = "microstar";
        HTTP_ADDR = "0.0.0.0";
        HTTP_PORT = 3000;
        ROOT_URL = "http://192.168.178.100:3000/";
        START_SSH_SERVER = true;
        SSH_LISTEN_PORT = 2222;
        SSH_PORT = 2222;
      };
      actions.ENABLED = true;
    };
  };

  services.forgejo-runner.instances.default = {
    enable = true;
    settings = {
      runner.labels = [
        "ubuntu-latest:docker://node:20-bookworm"
        "docker:docker://node:20-bookworm"
        # Runs directly on microstar, no container -- jobs must stick to
        # PATH-resolvable tools (hostPackages below), since NixOS isn't an
        # FHS filesystem and steps hardcoding /usr/bin/* paths won't find them.
        "native:host"
      ];
      server.connections.microstar = {
        url = "http://localhost:3000/";
        # Get this from Site Administration -> Actions -> Runners -> Create
        # new Runner on the running Forgejo instance -- not secret, but
        # unique per registration, so there's no real value to put here yet.
        uuid = "2403b0a3-3bfd-4e75-8b7b-67eac47a2543";
      };
    };
    hostPackages = [
      pkgs.bashInteractive
      pkgs.nodejs
      config.nix.package
    ];
    secrets.server.connections.microstar.token_url =
      config.sops.secrets.microstar_forgejo_runner_token.path;
  };

  # DynamicUser=yes forces a tmpfs-backed private /tmp (systemd can't bind-mount
  # a persistent host dir for a transient UID). microstar has 7.7G RAM and no
  # swap, so a multi-GB build artifact plus the upload action's own zip-staging
  # scratch space can exceed it (ENOSPC) even though the real disk has 80G+
  # free. Point TMPDIR at a real, disk-backed CacheDirectory instead.
  systemd.services."forgejo-runner-default" = {
    serviceConfig.CacheDirectory = "forgejo-runner-default";
    environment.TMPDIR = "/var/cache/forgejo-runner-default";
  };

  documentation.enable = false;

  networking.firewall.interfaces.br0.allowedTCPPorts = [
    22
    3000
    2222
  ];

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "@wheel"
    ];
  };

  environment.systemPackages = with pkgs; [
    helix
    git
    curl
    wget
    rsync
    htop
    tmux
  ];

  system.stateVersion = "26.05";
}
