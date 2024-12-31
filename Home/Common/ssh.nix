{ ... }:

{
  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";
    compression = true;
    extraConfig = ''
      # IdentityFile ~/.ssh/netzfabrik-gitlabkey.rsa
      # IdentityFile ~/.ssh/personalgithubkey
      ConnectTimeout 600
      ConnectionAttempts 10
      ForwardAgent yes
      StrictHostKeyChecking off
    '';
    matchBlocks = {
      "homePi" = {
        hostname = "192.168.178.215";
        user = "tim";
      };
      "nixos" = {
        hostname = "192.168.178.225";
        user = "tim";
      };
    };
  };
  

  services.ssh-agent.enable = true;
}
