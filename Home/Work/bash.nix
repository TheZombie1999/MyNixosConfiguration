{ config, pkgs, lib, ...}:

{
  programs.bash.initExtra = ''
    # export GITLAB_TOKEN=$(pass GITLAB_TOKEN)
    # export JIRA_API_TOKEN=$(pass jira/apitoken)
    # export CST_KEY_PASS=$(pass CST_KEY_PASS)

    # Add Bash Completion
    source /usr/share/bash-completion/completions/git  
  '';

  programs.bash.shellAliases = {
      buildPublisher = "ssh-add ~/.ssh/netzfabrik-gitlabkey.rsa ; export CST_KEY_PASS=$(pass CST_KEY_PASS) ; ./create-all.sh -n -A armhf Release";
      confluence="open \"https://varta-storage.atlassian.net/wiki/home\"";
      jira      ="open \"https://varta-storage.atlassian.net/\"";
      gitlab    ="open \"https://varta-storage.netzfabrik.cloud/\"";
      jenkins   ="open \"http://vartas018:8080/\"";
      # dashboard ="open \"http://ellwvsdevext1.varta.net:7575/board/default\"";   
  };
}
