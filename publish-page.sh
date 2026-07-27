#!/usr/bin/env bash
# Publish any self-contained HTML page to islands-ai.com/<path>
#
# Usage:  ./publish-page.sh <url-path> <path-to-page.html> ["commit message"]
#   <url-path>      where it lives under the domain, e.g. "acme" or "launch/acme".
#                   Lowercase, hyphens, and slashes only. Becomes <url-path>/index.html.
#   <page.html>     a self-contained HTML file (all CSS/JS/images inlined).
#   "commit msg"    optional; defaults to "page: <url-path>".
#
# Copies the file to <url-path>/index.html, commits, and pushes.
# GitHub Pages redeploys in ~1 min; the page goes live at the printed URL.
#
# This is the generic publisher. For AI Visibility Audits use publish.sh, which
# pins pages under audit/<company>.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REMOTE="https://github.com/islandsdev/islands-ai.git"

url_path="${1:-}"
src="${2:-}"
msg="${3:-}"

if [ -z "$url_path" ] || [ -z "$src" ]; then
  echo "usage: publish-page.sh <url-path> <path-to-page.html> [\"commit message\"]" >&2
  exit 1
fi
if [ ! -f "$src" ]; then
  echo "error: source file not found: $src" >&2
  exit 1
fi

# normalize: lowercase; spaces/underscores -> hyphens; keep a-z 0-9 - and /;
# collapse repeated/edge slashes so the path can't escape the repo.
url_path="$(printf '%s' "$url_path" \
  | tr '[:upper:]' '[:lower:]' \
  | tr ' _' '--' \
  | tr -cd 'a-z0-9/-' \
  | sed -E 's#/+#/#g; s#^/+##; s#/+$##')"
if [ -z "$url_path" ]; then echo "error: url-path empty after normalization" >&2; exit 1; fi
case "$url_path" in
  audit|audit/*) echo "error: 'audit/*' is reserved for the AI Visibility Audit; use publish.sh" >&2; exit 1;;
esac

# ensure the repo exists locally (clone if a fresh session)
if [ ! -d "$REPO_DIR/.git" ]; then
  echo "no local repo, cloning $REMOTE ..."
  git clone "$REMOTE" "$REPO_DIR"
fi

cd "$REPO_DIR"
git pull --quiet --ff-only origin main || true

dest="$url_path/index.html"
mkdir -p "$url_path"
cp "$src" "$dest"

git add "$dest"
if git diff --cached --quiet; then
  echo "no change: $dest is already up to date"
else
  git -c user.name='islandsdev' -c user.email='eng@islandshq.xyz' \
    commit --quiet -m "${msg:-page: $url_path}"
  git push --quiet origin main
fi

echo "published -> https://islands-ai.com/$url_path"
echo "(live in ~1 min once GitHub Pages redeploys)"
