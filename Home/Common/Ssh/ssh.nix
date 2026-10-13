{ pkgs, ... }:

{

  home.packages = [ pkgs.openssh ];

  home.file."sshconfig" = {
    target = ".ssh/config";
    source = ./config;
  };

  home.file."ssh_configs.d" = {
    target = ".ssh/ssh_configs.d";
    source = ./ssh_configs.d;
    recursive = true;
  };

  home.file."known_hosts.d" = {
    target = ".ssh/know_hosts.d";
    source = ./know_hosts.d;
    recursive = true;
  };

  services.ssh-agent = {
    enable = true;
    # OpenSSH's ssh-agent refuses every PKCS#11/FIDO middleware library by
    # default (post-CVE hardening) -- ssh-add -s/-S fails with "agent refused
    # operation" unless the library path matches one of these patterns. A
    # single "*" doesn't cross "/" (OpenSSH's own default is "/usr/lib*/*",
    # two explicit segments, not a recursive glob) -- "/nix/store/*" alone
    # only matches the package's own store path, never the nested
    # <pkg>/lib/*.so file actually passed to ssh-add.
    pkcs11Whitelist = [
      "/nix/store/*/lib/*"
      "/nix/store/*/lib/*/*"
    ];
  };
}
