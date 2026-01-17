{ pkgs, lib, ... }:
let
  nix-colors = import <nix-colors> { };
  nixgl = import <nixgl> { };
in
{
  imports = [
    nix-colors.homeManagerModules.default
    ../Common
  ];

  colorScheme = nix-colors.colorSchemes.gruvbox-dark-hard;

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "tim";
  home.homeDirectory = "/home/tim";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.11"; # Please read the comment before changing.

  home.packages = with pkgs; [
    direnv
    devenv
  ] ++ [ nixgl.auto.nixGLDefault ];

  systemd.user.services.custom-bash-service = {
          Unit = {
            Description = "";
            Documentation = "";
          };

          Service = {
            ExecStart = "${pkgs.writeShellScript "custom-script" (builtins.readFile ./custom-script.sh)}";
            Environment = "PATH=${lib.makeBinPath [ pkgs.curl pkgs.glib pkgs.qt5.qttools pkgs.xfconf pkgs.lxqt.pcmanfm-qt pkgs.feh pkgs.coreutils pkgs.findutils ]}:$PATH";
            Restart = "on-failure";
          };
        };

  systemd.user.timers.custom-bash-service = {
    Timer = {
      OnUnitActiveSec = "5minutes";
      Unit = "custom-bash-service.service";
    };

    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  programs.bash.initExtra = ''
    eval "$(direnv hook bash)"
  '';

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/tim/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "hx";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
