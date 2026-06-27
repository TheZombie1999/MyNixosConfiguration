{ ... }:

{
  home.file."claude-settings" = {
    source = ./settings.json;
    target = ".claude/settings.json";
  };

  home.file."claude-keybindings" = {
    source = ./keybindings.json;
    target = ".claude/keybindings.json";
  };
}
