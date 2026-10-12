{
  pkgs,
  config,
  inputs,
  ...
}:

{
  imports = [
    ./../Hardware/hetzner-nbg1-hardware-configuration.nix
    inputs.sops-nix.nixosModules.sops
  ];

  networking.hostName = "hetzner-nbg1";

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

  # Hetzner Cloud: statically-assigned IPv6 (not SLAAC/DHCPv6). IPv4 is a real
  # public primary IP (2.31.59.138, added 2026-10-12), assigned the same way
  # Hetzner always does it: a single /32 plus a point-to-point gateway, handed
  # out over DHCP -- nothing to pin statically here, useDHCP already picks up
  # whatever primary IPv4 is set in the Hetzner console/API, including if it's
  # ever changed there again.
  networking.useDHCP = false;
  networking.interfaces.eth0 = {
    useDHCP = true;
    ipv6.addresses = [
      {
        address = "2a01:4f8:1c1c:8a66::1";
        prefixLength = 64;
      }
    ];
  };
  networking.defaultGateway6 = {
    address = "fe80::1";
    interface = "eth0";
  };
  # Static IPv6 means nothing ever populates resolv.conf via DHCP/RA -- without
  # this, DNS resolution is completely broken (no nameservers at all), which
  # silently breaks anything that needs to resolve a hostname (e.g. ACME).
  networking.nameservers = [
    "2a01:4ff:ff00::add:1"
    "2a01:4ff:ff00::add:2"
  ];

  # GRUB (EFI, registered in NVRAM + installed as removable fallback). Hetzner
  # Cloud's virtual firmware won't boot a new bootloader unless the NVRAM boot
  # entry is actually updated, so canTouchEfiVariables must be true here.
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    devices = [ "nodev" ];
  };

  # 1GB RAM box -- swap needed to build/switch at all.
  swapDevices = [
    {
      device = "/swapfile";
      size = 1024;
    }
  ];

  services.openssh = {
    enable = true;
    # Declarative-only: without this, sshd also honors a manually-dropped
    # ~/.ssh/authorized_keys, which nixos-rebuild/deploy-rs never cleans up --
    # a one-time write access there would grant silent, persistent SSH access.
    # (authorizedKeysFiles alone is a no-op here: the sshd module makes its own
    # second, additive assignment to that same list option for
    # /etc/ssh/authorized_keys.d/%u, and NixOS merges list-option definitions
    # rather than letting one override another -- see
    # Specs/hetzner/04-ssh-authorized-keys-lockdown.md for the full trace.)
    authorizedKeysInHomedir = false;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      # No direct root SSH access at all -- deploy-rs connects as tim
      # (sshUser = "tim" in flake.nix) and escalates via passwordless sudo
      # (security.sudo.wheelNeedsPassword = false below) for activation, same
      # pattern as the existing nixos-onedev deploy node.
      PermitRootLogin = "no";
      X11Forwarding = false;
      # Off by default -- the "jump" user below gets it back via the Match
      # block, since permitopen alone does nothing while this is false.
      AllowTcpForwarding = false;
      AllowAgentForwarding = false;
      AllowUsers = [
        "tim"
        "jump"
      ];
      MaxAuthTries = 3;
      LoginGraceTime = 20;
      ClientAliveInterval = 300;
      ClientAliveCountMax = 2;
      LogLevel = "VERBOSE";
    };
    extraConfig = ''
      Match User jump
        AllowTcpForwarding yes
        # Verified live: authorized_keys permitopen= does NOT narrow this --
        # an explicit "PermitOpen none" here is a hard block the key's
        # permitopen= can't add exceptions back to (confirmed: it also
        # refused the one host the key *does* list), and leaving PermitOpen
        # unset here just inherits the base config's explicit "any" below
        # (NixOS always writes PermitOpen out explicitly, so there's no
        # implicit "unset" to fall back to). So this Match-level PermitOpen
        # is the actual, authoritative restriction -- not the permitopen= in
        # the jump user's authorized_keys entry, which is now redundant
        # documentation at best.
        PermitOpen 192.168.178.103:22
    '';
  };

  # Public-facing SSH port -- ban scanners/crawlers hammering it. Key-only auth
  # already blocks brute force, but this cuts log noise and connection churn.
  services.fail2ban = {
    enable = true;
    maxretry = 4;
    bantime = "1h";
    bantime-increment.enable = true;
    ignoreIP = [
      "127.0.0.1/8"
      "::1/128"
      # Tailscale CGNAT range -- once this host joins the tailnet
      # (Specs/hetzner/01-tailscale-join.md), tailnet peers should never be banned.
      "100.64.0.0/10"
    ];
  };

  # No authorized keys for root -- PermitRootLogin is "no" above, so this would be
  # inert anyway, but leaving it unset makes the "no root SSH access" intent
  # unambiguous rather than relying on sshd_config alone.
  #
  # Lingering fixes dbus-broker's user unit failing to reload on every switch (no
  # session stays open on a headless SSH box) -- deploy-rs treated that as a hard
  # activation failure and rolled back. Kept for root too even without SSH access,
  # since root still runs activation scripts via tim's sudo.
  users.users.root.linger = true;

  users.users.tim = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    linger = true;
    openssh.authorizedKeys.keys = [
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIK5ynhdh9jUSrKGll4ZOw4Krji+ipGNfsFKu6EmbEpVMAAAABHNzaDo="
    ];
  };

  # SSH bastion to nixos-onedev.local (192.168.178.103) only -- reachable via
  # the home-LAN subnet route proxmox1 advertises and this host accepts (see
  # services.tailscale above). No shell, no other forwarding: command= kills
  # any attempt at an interactive session on hetzner-nbg1 itself with this
  # key, and permitopen scopes the tunnel to exactly that one host and port
  # -- deliberately not the plain onedev.local git-server container (.101).
  # Usage: ssh -J jump@hetzner.nixhomelab.de tim@192.168.178.103
  users.users.jump = {
    isNormalUser = true;
    shell = pkgs.shadow; # no interactive shell needed, ProxyJump only uses direct-tcpip
    openssh.authorizedKeys.keys = [
      ''command="echo 'Bastion: port-forwarding only'",no-agent-forwarding,no-X11-forwarding,no-pty,permitopen="192.168.178.103:22" sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIK5ynhdh9jUSrKGll4ZOw4Krji+ipGNfsFKu6EmbEpVMAAAABHNzaDo=''
    ];
  };

  # No passwords anywhere -- SSH keys only, sudo never prompts.
  security.sudo.wheelNeedsPassword = false;
  # Only wheel members may invoke sudo at all (defense in depth; today that's
  # just "tim" -- root doesn't need sudo).
  security.sudo.execWheelOnly = true;
  users.users.root.hashedPassword = "!";

  # Back on dbus-broker (the NixOS default) -- lingering on every user above is the
  # actual fix for its reload-on-switch failure, so there's no need to drop to the
  # classic dbus-daemon.
  services.dbus.implementation = "broker";

  # Kernel/network hardening for a box with public inbound exposure.
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.secure_redirects" = 0;
    "net.ipv4.conf.default.secure_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.all.log_martians" = 1;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    "net.ipv4.tcp_syncookies" = 1;
    "kernel.kptr_restrict" = 2;
    "kernel.dmesg_restrict" = 1;
    "kernel.yama.ptrace_scope" = 1;
    "kernel.perf_event_paranoid" = 3;
    "fs.protected_hardlinks" = 1;
    "fs.protected_symlinks" = 1;
    "fs.suid_dumpable" = 0;
  };

  # Cap journal disk usage -- a log-flooding DoS shouldn't be able to fill the disk.
  # Raised from 200M so login-attempt history (sshd runs at LogLevel=VERBOSE, see
  # above) survives long enough to actually review -- this is a 19G disk with ~13G
  # free, so 1G is still a small, bounded slice of it.
  services.journald.extraConfig = "SystemMaxUse=1G";

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

  networking.firewall.allowedTCPPorts = [
    22
    80
    443
  ];

  security.acme = {
    acceptTerms = true;
    defaults.email = "timschneider733@gmail.com";
  };

  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    serverTokens = false;
    # Default level ("error") silently drops malformed-request/TLS-handshake noise --
    # "warn" surfaces that so scan/probe traffic actually shows up in error.log.
    # access.log already records every request (real client IP included, since
    # nothing proxies in front of nginx yet) and is rotated weekly/kept 26 weeks by
    # the module's own default logrotate rule -- no change needed there.
    logError = "/var/log/nginx/error.log warn";
    virtualHosts."hetzner.nixhomelab.de" = {
      default = true;
      enableACME = true;
      forceSSL = true;
      extraConfig = ''
        add_header Strict-Transport-Security "max-age=63072000; includeSubDomains" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-Frame-Options "DENY" always;
        add_header Referrer-Policy "strict-origin-when-cross-origin" always;
      '';
      locations."/".root = pkgs.writeTextDir "index.html" ''
        <!DOCTYPE html>
        <html>
          <head><title>hetzner-nbg1</title></head>
          <body><h1>Hello World</h1></body>
        </html>
      '';
    };
  };

  # Headless server managed over SSH -- manual/man pages and the nixpkgs source
  # tree they pull in (~500MB) aren't useful here.
  documentation.enable = false;

  system.stateVersion = "26.05";
}
