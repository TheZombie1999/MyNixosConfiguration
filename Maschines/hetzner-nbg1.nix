{ pkgs, ... }:

{
  imports = [
    ./../Hardware/hetzner-nbg1-hardware-configuration.nix
  ];

  networking.hostName = "hetzner-nbg1";

  # Hetzner Cloud: statically-assigned IPv6 (not SLAAC/DHCPv6), IPv4 is NAT-shared
  # (100.64.0.0/10) with no public default route -- DHCP covers it, no internet
  # egress over v4 either way.
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
    authorizedKeysFiles = [ "/etc/ssh/authorized_keys.d/%u" ];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      # deploy-rs logs in as root (sshUser = "root" in flake.nix) -- key-only, so
      # this stays prohibit-password rather than "no".
      PermitRootLogin = "prohibit-password";
      X11Forwarding = false;
      # No one needs port/agent forwarding through this host today. If the SSH
      # bastion in Specs/hetzner/03-ssh-bastion.md is implemented, that spec's
      # "jump" user needs a `Match User jump { AllowTcpForwarding yes; }` block
      # to override this -- permitopen alone does nothing while this is false.
      AllowTcpForwarding = false;
      AllowAgentForwarding = false;
      AllowUsers = [
        "root"
        "tim"
      ];
      MaxAuthTries = 3;
      LoginGraceTime = 20;
      ClientAliveInterval = 300;
      ClientAliveCountMax = 2;
      LogLevel = "VERBOSE";
    };
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

  users.users.root.openssh.authorizedKeys.keys = [
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIK5ynhdh9jUSrKGll4ZOw4Krji+ipGNfsFKu6EmbEpVMAAAABHNzaDo="
  ];
  # Lingering fixes dbus-broker's user unit failing to reload on every switch (no
  # session stays open on a headless SSH box) -- deploy-rs treated that as a hard
  # activation failure and rolled back. Set for every user on this host, not just
  # root, since deploy-rs/sudo can act as either.
  users.users.root.linger = true;

  users.users.tim = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    linger = true;
    openssh.authorizedKeys.keys = [
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIK5ynhdh9jUSrKGll4ZOw4Krji+ipGNfsFKu6EmbEpVMAAAABHNzaDo="
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
