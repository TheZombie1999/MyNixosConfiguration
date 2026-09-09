{
  writeShellApplication,
  claude-code,
  gnused,
  coreutils,
}:

writeShellApplication {
  name = "comment-code";
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

    prompt="Add doc comments above each function, struct, and enum explaining its purpose, parameters, and return value.
    Add an inline comment only if a line contains non-obvious logic.
    If nothing needs a comment, return the code unchanged.
    Preserve ALL whitespace and indentation exactly as given.
    Return ONLY the raw code — no markdown fences, no backticks, no explanation.

    <code>
    $code
    </code>"

    claude --model claude-sonnet-4-6 --print "$prompt" | sed '/^```/d'
  '';
}
