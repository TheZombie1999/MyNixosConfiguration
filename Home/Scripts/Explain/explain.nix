{
  writeShellApplication,
  claude-code,
  gnused,
  coreutils,
}:

writeShellApplication {
  name = "explain";
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

    prompt="Add an inline comment to every meaningful line of code explaining what it does.
    Focus on: unusual or rarely-used syntax, the origin and purpose of called functions (especially from imports/crates), the meaning of each argument passed to a function, potential problems or edge cases in the implementation, and any non-obvious behaviour.
    Do NOT add doc comments above functions or types — only inline comments on individual lines.
    Preserve ALL whitespace and indentation exactly as given.
    Return ONLY the raw annotated code — no markdown fences, no backticks, no explanation outside the comments.

    <code>
    $code
    </code>"

    claude --model claude-sonnet-4-6 --print "$prompt" | sed '/^```/d'
  '';
}
