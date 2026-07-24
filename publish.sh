#!/usr/bin/env bash
# Publish an AI Visibility Audit to islands-ai.com/audit/<slug>
#
# Usage:  ./publish.sh <company-slug> <path-to-audit.html> ["Company Name"]
#   <company-slug>  lowercase, hyphenated (e.g. hippo-insurance)
#   <path-to.html>  the HTML file produced by the /ai-visibility-audit skill
#   "Company Name"  optional, used only for the commit message
#
# Copies the file to audit/<slug>/index.html, commits, and pushes.
# GitHub Pages redeploys in ~1 min; the page goes live at the printed URL.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REMOTE="https://github.com/islandsdev/islands-ai.git"

slug="${1:-}"
src="${2:-}"
name="${3:-$slug}"

if [ -z "$slug" ] || [ -z "$src" ]; then
  echo "usage: publish.sh <company-slug> <path-to-audit.html> [\"Company Name\"]" >&2
  exit 1
fi
if [ ! -f "$src" ]; then
  echo "error: source file not found: $src" >&2
  exit 1
fi
# normalize slug: lowercase, spaces/underscores -> hyphens, strip anything else
slug="$(printf '%s' "$slug" | tr '[:upper:]' '[:lower:]' | tr ' _' '--' | tr -cd 'a-z0-9-')"
if [ -z "$slug" ]; then echo "error: slug empty after normalization" >&2; exit 1; fi

# ensure the repo exists locally (clone if a fresh session)
if [ ! -d "$REPO_DIR/.git" ]; then
  echo "no local repo, cloning $REMOTE ..."
  git clone "$REMOTE" "$REPO_DIR"
fi

cd "$REPO_DIR"
git pull --quiet --ff-only origin main || true

dest="audit/$slug/index.html"
mkdir -p "audit/$slug"
cp "$src" "$dest"

git add "$dest"
if git diff --cached --quiet; then
  echo "no change: $dest is already up to date"
else
  git -c user.name='islandsdev' -c user.email='eng@islandshq.xyz' \
    commit --quiet -m "audit: $name"
  git push --quiet origin main
fi

echo "published -> https://islands-ai.com/audit/$slug"
echo "(live in ~1 min once GitHub Pages redeploys)"
