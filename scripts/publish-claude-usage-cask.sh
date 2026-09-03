#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:?Usage: scripts/publish-claude-usage-cask.sh <version>}"
TAG="v${VERSION}"
REPO="posalex/ClaudeUsage"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CASK_PATH="Casks/claude-usage.rb"
CASK_FILE="$ROOT_DIR/$CASK_PATH"
ASSET_URL="https://github.com/${REPO}/releases/download/${TAG}/ClaudeUsage.zip"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-30}"
RETRY_SECONDS="${RETRY_SECONDS:-10}"

[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
  echo "Version must use the form major.minor.patch (for example: 1.1.1)." >&2
  exit 2
}

cd "$ROOT_DIR"

test "$(git branch --show-current)" = "main" || {
  echo "Cask publishing must run from main." >&2
  exit 1
}
test -z "$(git status --porcelain)" || {
  echo "Tap working tree is not clean." >&2
  exit 1
}

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
ARCHIVE="$TMP_DIR/ClaudeUsage.zip"

for attempt in $(seq 1 "$MAX_ATTEMPTS"); do
  echo "==> Downloading release asset (attempt $attempt/$MAX_ATTEMPTS)"
  if curl --fail --location --silent --show-error --output "$ARCHIVE" "$ASSET_URL"; then
    break
  fi

  if [ "$attempt" = "$MAX_ATTEMPTS" ]; then
    echo "Release asset did not become available: $ASSET_URL" >&2
    exit 1
  fi
  sleep "$RETRY_SECONDS"
done

SHA256="$(shasum -a 256 "$ARCHIVE" | awk '{print $1}')"
perl -0pi -e "s/version \"[^\"]+\"/version \"$VERSION\"/; s/sha256 \"[^\"]+\"/sha256 \"$SHA256\"/" "$CASK_FILE"

echo "==> Checking Cask syntax"
ruby -c "$CASK_FILE"

git add "$CASK_PATH"
git commit -m "Update claude-usage to $TAG"
git push origin main

# Recent Homebrew versions no longer accept a cask file path for `brew audit`.
# Refresh the installed copy of this tap, then audit the just-published Cask by
# its tap-qualified name.
BREW_TAP_DIR="$(brew --repository posalex/tap)"
git -C "$BREW_TAP_DIR" pull --ff-only origin main
echo "==> Auditing published Cask"
HOMEBREW_NO_AUTO_UPDATE=1 brew audit --cask --strict posalex/tap/claude-usage

echo "Cask published: posalex/tap/claude-usage $VERSION"
