{
  writeShellApplication,
  claude-code,
  coreutils,
}:

writeShellApplication {
  name = "ask";
  runtimeInputs = [
    claude-code
    coreutils
  ];
  text = ''
    if [ -z "''${1:-}" ]; then
      echo "Usage: ask <question>" >&2
      exit 1
    fi

    claude --model claude-sonnet-4-6 --print "$1"
  '';
}
