{ ... }:
{
  home.file."shellcheckrc" = {
    source = ./shellcheckrc;
    target = ".shellcheckrc";
  };
}
