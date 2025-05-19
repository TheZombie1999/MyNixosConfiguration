{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.packages = with pkgs; [
    chatgpt-shell-cli
    blesh
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

      function yy() {
      	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
      	yazi "$@" --cwd-file="$tmp"
      	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
      		builtin cd -- "$cwd"
      	fi
      	rm -f -- "$tmp"
      }

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
      export OPENAI_KEY="op://Money/Chatgpt - Api key/password"
      export LANG=C.UTF-8

      eval "$(zellij setup --generate-auto-start bash)"

      # source "$(blesh-share)"/ble.sh --attach=none # does not work currently
      # [[ ! ''${BLE_VERSION-} ]] || ble-attach
    '';
    shellAliases = {
      chatgpt = "op run -- chatgpt.sh";
      brunel = "open \"https://connect.brunel.net/\"";
      ls = "eza --group-directories-first -I \"jre|snap|Music|CLionProjects|Desktop|Pictures|Projects\"";
      ip = "ip -c";
      ll = "eza --long --git --header --no-user --no-time --group-directories-first";
      la = "eza --all -1 --color=never | grep -E \"^\\..*$\"";
    };
  };

  programs.atuin = {
    enable = true;
    enableBashIntegration = true;
  };

  # programs.hstr = {
  #   enable = true;
  #   enableBashIntegration = true;
  # };

  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    options = [ "--cmd cd" ];
  };
}
