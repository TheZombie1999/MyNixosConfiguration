{
  writeShellApplication,
  claude-code,
  gnused,
  coreutils,
}:

writeShellApplication {
  name = "about";
  runtimeInputs = [
    claude-code
    gnused
    coreutils
  ];
  text = ''
    if [ -z "''${1:-}" ]; then
      echo "Usage: about <question>" >&2
      exit 1
    fi

    question="$1"
    code=$(cat)

    if [ -z "$(echo "$code" | tr -d '[:space:]')" ]; then
      echo "Error: no code provided on stdin" >&2
      exit 1
    fi

    prompt="Answer the question about the code below.
    Detect the language from the code and format the answer as a comment using that language's native comment style.
    The answer may span multiple comment lines if needed.
    Return ONLY the comment — no markdown fences, no backticks, no extra explanation.

    Question: $question

    <code>
    $code
    </code>"

    answer=$(claude --model claude-sonnet-4-6 --print "$prompt" | sed '/^```/d')

    printf '%s\n\n%s\n' "$code" "$answer"
  '';
}
