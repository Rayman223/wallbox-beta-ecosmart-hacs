#!/usr/bin/env bash
# Sync the wallbox_beta_ecosmart integration from the Home Assistant Core fork
# into this HACS distribution repo.
#
# Usage:
#   ./sync-from-core.sh            # sync only
#   ./sync-from-core.sh --push     # sync + git add/commit/push
#
# The source manifest.json (in the core fork) is left untouched. A `version`
# field is injected into the copied manifest only, so the core fork stays
# clean for an upstream PR (core integrations must NOT carry a version field).

set -euo pipefail

# --- Config -----------------------------------------------------------------
CORE_REPO="/var/www/home-assistant-core"
SRC_DIR="${CORE_REPO}/homeassistant/components/wallbox_beta_ecosmart"
DEST_DIR_REL="custom_components/wallbox_beta_ecosmart"
HACS_REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_DIR="${HACS_REPO_DIR}/${DEST_DIR_REL}"
BASE_VERSION="0.1.0"

PUSH=0
[[ "${1:-}" == "--push" ]] && PUSH=1

# --- Sanity checks ----------------------------------------------------------
[[ -d "$SRC_DIR" ]] || { echo "ERROR: source not found: $SRC_DIR" >&2; exit 1; }
[[ -d "$HACS_REPO_DIR/.git" ]] || { echo "ERROR: $HACS_REPO_DIR is not a git repo" >&2; exit 1; }

# --- Compute version --------------------------------------------------------
# Patch is YYYYMMDDHHMM so every sync produces a strictly newer SemVer version
# (HACS uses awesomeversion which orders by major.minor.patch; build metadata
# after `+` is ignored for ordering but kept for traceability).
CORE_SHA="$(git -C "$CORE_REPO" rev-parse --short HEAD)"
STAMP="$(date +%Y%m%d%H%M)"
VERSION="0.1.${STAMP}+sha-${CORE_SHA}"

echo ">> Source : $SRC_DIR"
echo ">> Dest   : $DEST_DIR"
echo ">> Version: $VERSION (core@$CORE_SHA)"

# --- Sync -------------------------------------------------------------------
mkdir -p "$DEST_DIR"
rsync -av --delete \
  --exclude='test_*.py' \
  --exclude='Plan*.md' \
  --exclude='__pycache__/' \
  --exclude='*.pyc' \
  --exclude='.pytest_cache/' \
  "$SRC_DIR"/ "$DEST_DIR"/

# --- Inject version into manifest -------------------------------------------
MANIFEST="$DEST_DIR/manifest.json"
[[ -f "$MANIFEST" ]] || { echo "ERROR: manifest.json missing after rsync" >&2; exit 1; }

tmp="$(mktemp)"
jq --arg v "$VERSION" '. + {version: $v}' "$MANIFEST" > "$tmp"
mv "$tmp" "$MANIFEST"
echo ">> Injected version=$VERSION into $MANIFEST"

# --- Generate translations/en.json from strings.json ------------------------
# Required for HACS custom_components: HA reads translations from
# <integration>/translations/<lang>.json, not from strings.json (which is
# only the Lokalise source for core integrations, gitignored in HA core).
# strings.json schema is identical to translations/en.json, so we copy verbatim.
STRINGS="$DEST_DIR/strings.json"
TRANSLATIONS_DIR="$DEST_DIR/translations"
[[ -f "$STRINGS" ]] || { echo "ERROR: strings.json missing after rsync" >&2; exit 1; }
mkdir -p "$TRANSLATIONS_DIR"
cp "$STRINGS" "$TRANSLATIONS_DIR/en.json"
echo ">> Generated $TRANSLATIONS_DIR/en.json from strings.json"

# --- Git -------------------------------------------------------------------
cd "$HACS_REPO_DIR"
git add -A "$DEST_DIR_REL"

if git diff --cached --quiet; then
  echo ">> No changes to commit."
  exit 0
fi

if [[ $PUSH -eq 1 ]]; then
  git commit -m "sync from core@${CORE_SHA} (v${VERSION})"
  git push -u origin "$(git branch --show-current)"
  echo ">> Pushed."
else
  echo ">> Staged changes. Run with --push to commit and push automatically,"
  echo "   or commit manually: git commit -m 'sync from core@${CORE_SHA}' && git push"
fi
