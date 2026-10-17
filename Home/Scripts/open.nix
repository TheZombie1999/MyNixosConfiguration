{
  writeShellApplication,
  chromium,
  coreutils,
}:

writeShellApplication {
  name = "open";
  runtimeInputs = [
    chromium
    coreutils
  ];
  text = ''
    nohup nixGL chromium --app="$1" >/dev/null 2>/dev/null &
  '';
}
