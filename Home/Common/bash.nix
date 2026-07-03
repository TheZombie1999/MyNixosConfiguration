{
  lib,
  pkgs,
  ...
}:

{

  home.packages = with pkgs; [
    direnv
  ];

  programs.bash = {
    enable = true;
    enableCompletion = true;
    bashrcExtra = ''
      # TERM=alacritty
    '';
    # historyIgnore = [ "ls" "exit" "cd" "hx" "broot" ];
    initExtra = ''
      ${lib.strings.fileContents ../Scripts/Colors/colors.include}

      parse_git_branch() {
        local branch="$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/')"

        if [ -n "''${branch}" ] ; then
          printf "\n Branch: %s\n" "''${branch}"
        fi
      }

      get_root() {
        local root=$(git rev-parse --show-toplevel 2> /dev/null)



        if [ -n "''${root}" ] ; then
          printf "\n\tProjectRoot: %s\n" "''${root}"
        fi
      }

      export PS1="\n$pur[ \$(date +%T) ]$clr $red\u@\h$clr $grn[ \w ]$clr $blu\$(parse_git_branch)$clr $cyn\$(get_root)$clr \n-> "

      export EDITOR=hx
      export LANG=C.UTF-8
      export NIXPKGS_ALLOW_UNFREE=1

      if [ -z "$SSH_CLIENT" ] && [ -z "$SSH_TTY" ]; then
          eval "$(zellij setup --generate-auto-start bash)"
      fi

      eval "$(direnv hook bash)"
    '';
    shellAliases = {
      ls = "eza --group-directories-first -I \"jre|snap|Music|CLionProjects|Desktop\"";
      ip = "ip -c";
      ll = "eza --long --git --header --no-user --no-time --group-directories-first";
      la = "eza --all -1 --color=never | grep -E \"^\\..*$\"";
    };
  };

  programs.atuin = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    options = [ "--cmd cd" ];
  };
}
