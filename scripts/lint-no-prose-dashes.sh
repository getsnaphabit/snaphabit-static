#!/usr/bin/env bash
# Scripts/lint-no-prose-dashes.sh
#
# Fail the commit if any *newly added* prose content contains a dash used
# as sentence punctuation. Enforces Jason's standing rule
# (Docs/ClaudeMemory/feedback_no_emdashes.md): no em dashes, no en dashes,
# no hyphens-as-separator in prose. Compound-word hyphens (on-device,
# privacy-first, real-time) stay allowed because the hyphen is part of
# the word, not prose punctuation.
#
# Detection pattern: " [-—–] " (hyphen U+002D, em dash U+2014, or en dash
# U+2013 flanked by spaces on both sides) in added prose content.
#
# Diff-scoped: reads `git diff --cached -U0` and checks only `+` lines
# (the lines this commit is ADDING). Pre-existing violations in the
# same file are not flagged. Aligns with Web Claude's original snippet
# while adding per-file-type prose extraction.
#
# File scope:
#   .md        : inline code spans stripped, Markdown bullet markers
#                (`- ` `* ` `+ ` at line start) stripped from each added line.
#   .html      : HTML tags stripped from each added line; attribute values
#                removed. Added lines inside <script>/<style>/<!-- -->
#                cannot be easily detected line-by-line, so we accept some
#                imprecision here.
#   .xcstrings : only added lines that match `"value" : "..."` are scanned,
#                and only the string contents.
#   (other file types ignored: Swift, CSS, Python, shell use dashes
#    legitimately in arithmetic, calc, and option flags.)
#
# Called from .git/hooks/pre-commit. Exits 0 on clean, 1 on any match.

set -Eeuo pipefail

# Collect the raw minimal-context diff once.
DIFF=$(git diff --cached -U0 --no-color --diff-filter=ACM || true)
if [[ -z "$DIFF" ]]; then
  exit 0
fi

python3 - <<'PY'
import os, re, subprocess, sys

PROSE_DASH = re.compile(r' [-—–] ')
BULLET_PREFIX = re.compile(r'^\s*[-*+]\s')
MD_INLINE_CODE = re.compile(r'`[^`\n]*`')
HTML_TAG = re.compile(r'<[^>]+>')
XCSTRINGS_VALUE = re.compile(r'"value"\s*:\s*"((?:[^"\\]|\\.)*)"')

diff = subprocess.run(
    ['git', 'diff', '--cached', '-U0', '--no-color', '--diff-filter=ACM'],
    capture_output=True, text=True, check=True,
).stdout

current_file = None
current_lineno = 0
violations = []

def strip_for_md(line):
    line = MD_INLINE_CODE.sub(lambda m: ' ' * len(m.group(0)), line)
    # Strip a leading bullet marker so its dash is not treated as prose.
    m = BULLET_PREFIX.match(line)
    if m:
        line = ' ' * len(m.group(0)) + line[m.end():]
    return line

def strip_for_html(line):
    return HTML_TAG.sub(' ', line)

def check_line(path, lineno, raw):
    if path.endswith('.md'):
        text = strip_for_md(raw)
    elif path.endswith(('.html', '.htm')):
        text = strip_for_html(raw)
    elif path.endswith('.xcstrings'):
        m = XCSTRINGS_VALUE.search(raw)
        if not m:
            return
        try:
            text = m.group(1).encode().decode('unicode_escape', errors='replace')
        except Exception:
            text = m.group(1)
    else:
        return
    if PROSE_DASH.search(text):
        violations.append((path, lineno, raw.rstrip()))

for line in diff.split('\n'):
    # Track current file from +++ headers
    if line.startswith('+++ b/'):
        current_file = line[len('+++ b/'):]
        continue
    if line.startswith('--- ') or line.startswith('+++ '):
        continue
    # Track line position from @@ hunk markers: @@ -a,b +c,d @@ ...
    m = re.match(r'^@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@', line)
    if m:
        current_lineno = int(m.group(1))
        continue
    if not current_file:
        continue
    # Only check added lines (not context, not removed)
    if line.startswith('+') and not line.startswith('+++'):
        content = line[1:]  # strip the leading '+'
        check_line(current_file, current_lineno, content)
        current_lineno += 1
    elif line.startswith(' '):
        current_lineno += 1
    # removed lines (leading '-' not '---') do not advance line counter

for p, i, l in violations:
    print(f'{p}:{i}: {l}')

if violations:
    print()
    print('lint-no-prose-dashes: space-flanked dash in newly added prose.')
    print('Rule: no em dashes, no en dashes, no hyphens as sentence punctuation.')
    print('Use commas, parentheses, colons, semicolons, or restructure.')
    print('Compound-word hyphens (on-device, privacy-first) stay fine.')
    print('See Docs/ClaudeMemory/feedback_no_emdashes.md.')
    sys.exit(1)
sys.exit(0)
PY
