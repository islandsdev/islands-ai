#!/usr/bin/env bash
# Host any raw file (PDF, image, etc.) on the Islands domain (our "CDN").
#
# Usage:  ./publish-asset.sh <url-path> <path-to-file> ["commit message"]
#   <url-path>   where it lives under the domain, e.g. "acme/brief.pdf" or
#                "assets/whitepaper.pdf". Lowercase, hyphens, slashes, one dot for
#                the extension. Served verbatim at islands-ai.com/<url-path>.
#   <file>       the file to host (PDF, PNG, SVG, etc.).
#   "commit msg" optional; defaults to "asset: <url-path>".
#
# Unlike publish-page.sh (which wraps HTML as <path>/index.html), this copies the
# file to the exact path so it downloads/renders directly. GitHub Pages serves it
# in ~1 min at the printed URL.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REMOTE="https://github.com/islandsdev/islands-ai.git"

url_path="${1:-}"
src="${2:-}"
msg="${3:-}"

if [ -z "$url_path" ] || [ -z "$src" ]; then
  echo "usage: publish-asset.sh <url-path> <path-to-file> [\"commit message\"]" >&2
  exit 1
fi
if [ ! -f "$src" ]; then
  echo "error: source file not found: $src" >&2
  exit 1
fi

# normalize: lowercase; spaces/underscores -> hyphens; keep a-z 0-9 - . and /;
# collapse repeated/edge slashes so the path can't escape the repo.
url_path="$(printf '%s' "$url_path" \
  | tr '[:upper:]' '[:lower:]' \
  | tr ' _' '--' \
  | tr -cd 'a-z0-9/.-' \
  | sed -E 's#/+#/#g; s#^/+##; s#/+$##')"
if [ -z "$url_path" ]; then echo "error: url-path empty after normalization" >&2; exit 1; fi
case "$url_path" in
  */index.html|index.html) echo "error: use publish-page.sh for pages" >&2; exit 1;;
  audit|audit/*) echo "error: 'audit/*' is reserved for the AI Visibility Audit" >&2; exit 1;;
esac

if [ ! -d "$REPO_DIR/.git" ]; then
  echo "no local repo, cloning $REMOTE ..."
  git clone "$REMOTE" "$REPO_DIR"
fi

cd "$REPO_DIR"
git pull --quiet --ff-only origin main || true

dir="$(dirname "$url_path")"
[ "$dir" != "." ] && mkdir -p "$dir"
cp "$src" "$url_path"

git add "$url_path"
if git diff --cached --quiet; then
  echo "no change: $url_path is already up to date"
else
  git -c user.name='islandsdev' -c user.email='eng@islandshq.xyz' \
    commit --quiet -m "${msg:-asset: $url_path}"
  git push --quiet origin main
fi

echo "hosted -> https://islands-ai.com/$url_path"
echo "(live in ~1 min once GitHub Pages redeploys)"
