#!/usr/bin/env bash

SCRIPT="$HOME/Downloads/comment-code"
PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

assert_contains() {
    local label="$1" pattern="$2" output="$3"
    if echo "$output" | grep -qP "$pattern"; then pass "$label"; else fail "$label"; fi
}

assert_not_contains() {
    local label="$1" pattern="$2" output="$3"
    if echo "$output" | grep -qP "$pattern"; then fail "$label"; else pass "$label"; fi
}

assert_exit_nonzero() {
    local label="$1" input="$2"
    echo "$input" | "$SCRIPT" > /dev/null 2>&1
    if [ $? -ne 0 ]; then pass "$label"; else fail "$label"; fi
}

run() {
    echo "$1" | "$SCRIPT" 2>/dev/null
}

# ── Empty / degenerate input ─────────────────────────────────────────────────
echo
echo "Empty / degenerate input"

assert_exit_nonzero "empty string exits non-zero" ""
assert_exit_nonzero "whitespace-only exits non-zero" "   "

# ── Markdown fences ──────────────────────────────────────────────────────────
echo
echo "No markdown fences in output"

OUT=$(run 'fn add(a: i32, b: i32) -> i32 { a + b }')
assert_not_contains "no opening fence"  '```' "$OUT"
assert_not_contains "no closing fence"  '^```$' "$OUT"

# ── Indentation preservation ─────────────────────────────────────────────────
echo
echo "Indentation preservation"

OUT=$(run '    let x = 1;')
assert_contains     "4-space indent preserved"  '^\s{4}' "$OUT"
assert_not_contains "no extra leading newline"  '^\n'    "$OUT"

OUT=$(run '        let nested = true;')
assert_contains "8-space indent preserved" '^\s{8}' "$OUT"

OUT=$(run 'fn outer() {
    fn inner() {
        let x = 1;
    }
}')
assert_contains "nested 4-space indent preserved" '^\s{4}fn inner' "$OUT"
assert_contains "nested 8-space indent preserved" '^\s{8}let x'   "$OUT"

# ── Doc comments on functions ─────────────────────────────────────────────────
echo
echo "Doc comments added to functions"

OUT=$(run 'fn clamp(val: f32, lo: f32, hi: f32) -> f32 {
    if val < lo { lo } else if val > hi { hi } else { val }
}')
assert_contains "fn gets /// doc comment"    '^///'      "$OUT"
assert_contains "original fn signature kept" 'fn clamp'  "$OUT"
assert_contains "body preserved"             'lo } else'  "$OUT"

OUT=$(run 'pub fn greet(name: &str) -> String {
    format!("Hello, {}!", name)
}')
assert_contains "pub fn gets doc comment"   '^///'         "$OUT"
assert_contains "pub fn signature present"  'pub fn greet' "$OUT"

OUT=$(run 'async fn fetch(url: &str) -> Result<String, Error> {
    let resp = client.get(url).send().await?;
    Ok(resp.text().await?)
}')
assert_contains "async fn gets doc comment"  '^///'            "$OUT"
assert_contains "async fn signature present" 'async fn fetch'  "$OUT"

# ── Multiple functions all get doc comments ───────────────────────────────────
echo
echo "Multiple functions"

OUT=$(run 'fn clamp(val: f32, lo: f32, hi: f32) -> f32 {
    if val < lo { lo } else if val > hi { hi } else { val }
}

fn lerp(a: f32, b: f32, t: f32) -> f32 {
    a + (b - a) * t
}')
DOC_COUNT=$(echo "$OUT" | grep -cP '^///')
if [ "$DOC_COUNT" -ge 2 ]; then pass "both functions get doc comments"; else fail "both functions get doc comments (got $DOC_COUNT)"; fi

# ── Struct and enum get doc comments ─────────────────────────────────────────
echo
echo "Structs and enums"

OUT=$(run 'struct Point {
    x: f64,
    y: f64,
}')
assert_contains "struct gets doc comment" '^///'         "$OUT"
assert_contains "struct name preserved"   'struct Point' "$OUT"
assert_contains "fields preserved"        'x: f64'       "$OUT"

OUT=$(run 'enum Direction {
    North,
    South,
    East,
    West,
}')
assert_contains "enum gets doc comment"  '^///'            "$OUT"
assert_contains "enum name preserved"    'enum Direction'  "$OUT"
assert_contains "variants preserved"     'North'           "$OUT"

# ── Code logic unchanged ──────────────────────────────────────────────────────
echo
echo "Code logic unchanged"

OUT=$(run 'fn factorial(n: u64) -> u64 {
    if n == 0 { 1 } else { n * factorial(n - 1) }
}')
assert_contains "if preserved"         'if n == 0'          "$OUT"
assert_contains "recursive call kept"  'factorial\(n - 1\)' "$OUT"
assert_contains "return value kept"    '\{ 1 \}'            "$OUT"

# ── Single lines ──────────────────────────────────────────────────────────────
echo
echo "Single lines"

OUT=$(run 'let x = 1;')
assert_contains "obvious single line returned"   'let x = 1'       "$OUT"

OUT=$(run '        let tmp = a + b;')
assert_contains "indented single line returned"  'let tmp = a \+ b' "$OUT"
assert_contains "indented single line has indent" '^\s{8}'          "$OUT"

# ── Non-obvious inline comment ────────────────────────────────────────────────
echo
echo "Non-obvious logic gets inline comment"

OUT=$(run 'let mask = (1 << n) - 1;')
assert_contains "bitmask line has comment" '//' "$OUT"

OUT=$(run 'let result = (a ^ b) & !(a & b);')
assert_contains "XOR logic has comment" '//' "$OUT"

# ── Summary ───────────────────────────────────────────────────────────────────
echo
TOTAL=$((PASS + FAIL))
echo "Results: $PASS/$TOTAL passed"
[ $FAIL -eq 0 ] && exit 0 || exit 1
