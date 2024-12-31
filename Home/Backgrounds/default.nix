{ ... }:

{
  home.file."backgrounds-light" = {
    source = ./Light;
    recursive = true;
    target = "Backgrounds/Light";
  };
  home.file."backgrounds-dark" = {
    source = ./Dark;
    recursive = true;
    target = "Backgrounds/Dark";
  };
}
