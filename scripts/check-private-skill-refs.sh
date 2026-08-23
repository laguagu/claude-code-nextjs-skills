#!/bin/sh
# Fail if a file that ships in this repo points at a skill that does not.
#
# `skills/` is a junction to a local collection that is larger than the public
# set, so a private skill is present on disk here and absent for anyone who
# clones. A reference written while looking at the local tree therefore reads
# fine locally and lands as a dead pointer in the published repo. That has
# happened twice: `nextjs-shadcn` sent readers to `ui-signature` and `go-ui`,
# and `e2e-tester` handed design critique to `/go-ui` four times, once in the
# frontmatter description.
#
# The private set is read from .gitignore rather than duplicated here, so
# un-ignoring a skill is all it takes to make references to it legal.
#
# Three forms count: backticked (`name`), slash (/name), and a bare YAML list
# item ("  - name"), which is how an agent frontmatter declares a skill it needs
# — a form that carries no punctuation to grep for and would otherwise slip
# through. Prose that names a skill as the contents of some *other* repo — as
# README's "See Also" does — is not a pointer into this one and must not fail
# the check.
#
# One grep over the whole file list, not one per file: a per-file loop is a
# fork per tracked file, and under Git Bash on Windows that hits the MSYS fork
# limit and the hook starts printing "Resource temporarily unavailable" instead
# of a verdict.

set -e
cd "$(git rev-parse --show-toplevel)"

private=$(grep -oE '^skills/[a-z0-9-]+/' .gitignore | sed 's|^skills/||; s|/$||' | paste -sd'|' -)
if [ -z "$private" ]; then
  echo "check-private-skill-refs: no private skills listed in .gitignore; nothing to check"
  exit 0
fi

pattern="\`(${private})\`|/(${private})\b|^[[:space:]]*-[[:space:]]+(${private})[[:space:]]*$"

hits=$(git ls-files -z '*.md' | xargs -0 grep -nHoE "$pattern" 2>/dev/null || true)

if [ -n "$hits" ]; then
  echo "Tracked files reference skills that are gitignored (dead pointers for anyone cloning):"
  echo
  echo "$hits" | sed 's|^|  |'
  cat <<'EOF'

Either drop the reference and keep its portable half as plain advice, or
un-ignore the skill in .gitignore if it is meant to ship after all.
EOF
  exit 1
fi

echo "check-private-skill-refs: OK — no tracked file points at a private skill"
