{ config, pkgs, lib, ...}:

{
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
          git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
        }

        get_root() {
          local root=$(git rev-parse --show-toplevel 2> /dev/null)

          if [ -n "''${root}" ] ; then
            printf "\n\tProjectRoot: %s\n" "''${root}"
          fi
        }

        export PS1="\n$pur[ \$(date +%T) ]$clr $red\u@\h$clr $grn[ \w ]$clr $blu\$(parse_git_branch)$clr $cyn\$(get_root)$clr \n-> "

        
        PROMPT_COMMAND='history -a'


        export EDITOR=hx
      ''; 
      shellAliases = {     
        brunel="open \"https://connect.brunel.net/\"";

        ls="eza --group-directories-first -I \"jre|snap|Music|CLionProjects|Desktop|Pictures|Projects\"";
        ip="ip -c";
        ll="eza --long --git --header --no-user --no-time --group-directories-first";
        cd="z";
        la="eza --all -1 --color=never | grep -E \"^\\..*$\"";
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
  };
} 
