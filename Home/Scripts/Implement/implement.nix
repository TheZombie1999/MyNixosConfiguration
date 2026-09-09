{
  writeShellApplication,
  claude-code,
  gnused,
  coreutils,
}:

writeShellApplication {
  name = "implement";
  runtimeInputs = [
    claude-code
    gnused
    coreutils
  ];
  text = ''
    code=$(cat)

    if [ -z "$(echo "$code" | tr -d '[:space:]')" ]; then
      echo "Error: no code provided on stdin" >&2
      exit 1
    fi

    prompt="Implement the function signature provided. If a comment above the signature describes requirements, follow them exactly.
    Preserve the exact signature — do not change its name, parameters, or return type.
    Preserve ALL whitespace and indentation exactly as given.
    Return ONLY the raw implementation — no doc comments, no inline comments, no markdown fences, no backticks, no explanation.

    <code>
    $code
    </code>"

    claude --model claude-sonnet-4-6 --print "$prompt" | sed '/^```/d'
  '';
}
