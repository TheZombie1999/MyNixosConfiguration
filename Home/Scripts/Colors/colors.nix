{ writeTextFile }:

writeTextFile {
  name = "colors";
  text = builtins.readFile ./colors.include;
  destination = "/Colors/colors.include";
}
