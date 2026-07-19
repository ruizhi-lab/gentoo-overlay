#!/bin/bash
# Check ruizhi-overlay packages for upstream updates.
# Only outputs results when a newer version is found.
# Usage: ./check-updates.sh [--json]
#
# Entry format: "category/package|github_repo|version_prefix"

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OVERLAY_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

PKGS=(
  "net-proxy/v2ray|v2fly/v2ray-core|v"
  "net-proxy/v2ray-bin|v2fly/v2ray-core|v"
  "net-proxy/v2rayA|v2rayA/v2rayA|v"
  "dev-libs/v2ray-geoip|v2fly/geoip|"
  "dev-libs/v2ray-geoip-bin|v2fly/geoip|"
  "dev-libs/v2ray-domain-list-community-bin|v2fly/domain-list-community|"
  "dev-libs/v2ray-rules-dat-bin|Loyalsoldier/v2ray-rules-dat|"
  "net-proxy/Xray|XTLS/Xray-core|v"
  "net-proxy/Xray-bin|XTLS/Xray-core|v"
  "net-proxy/qv2ray|Qv2ray/Qv2ray|v"
  "net-proxy/qvplugin-command|Qv2ray/QvPlugin-Command|v"
  "net-proxy/qvplugin-ss|Qv2ray/QvPlugin-SS|v"
  "net-proxy/qvplugin-trojan|Qv2ray/QvPlugin-Trojan|v"
  "net-proxy/qvplugin-trojan-go|Qv2ray/QvPlugin-Trojan-Go|v"
  "app-text/goldendict-ng|xiaoyifang/goldendict-ng|v"
  "app-text/quarto-bin|quarto-dev/quarto-cli|v"
  "kde-misc/latte-dock-ng|ruizhi-lab/latte-dock-ng|"
  "media-fonts/sarasa-gothic|be5invis/Sarasa-Gothic|v"
  "media-fonts/sarasa-term-sc-nerd|laishulu/Sarasa-Term-SC-Nerd|v"
  "media-sound/yesplaymusic-bin|qier222/YesPlayMusic|v"
  "dev-libs/singleapplication|itay-grudev/SingleApplication|v"
  "media-libs/openslide|openslide/openslide|v"
  "media-libs/libdicom|ImagingDataCommons/libdicom|v"
  "net-misc/xrdp|neutrinolabs/xrdp|v"
  "net-misc/xorgxrdp|neutrinolabs/xorgxrdp|v"
  "net-proxy/v2rayn-bin|2dust/v2rayN|"
)

# Repos that only use tags (no GitHub releases)
TAG_ONLY_REPOS=("ruizhi-lab/latte-dock-ng")

GH_API="${GITHUB_API_URL:-https://api.github.com}"
CURL_OPTS="${CURL_OPTS:--s}"
OUTPUT_JSON="${1:-}"
[[ "$OUTPUT_JSON" == "--json" ]] && OUTPUT_JSON=true || OUTPUT_JSON=false

get_current_version() {
  find "${OVERLAY_ROOT}/$1" -name '*.ebuild' ! -name '*9999*' 2>/dev/null \
    | sed 's/.*-\([0-9][^-]*\)\(-r[0-9]\)\?\.ebuild/\1/' \
    | sort -V | tail -1
}

# Get the base version without snapshot suffix (_pYYYYMMDD)
base_version() {
  echo "${1%%_p*}"
}

# True if the version has a git snapshot suffix (ebuild _pYYYYMMDD)
has_snapshot() {
  [[ "$1" == *_p[0-9]* ]]
}

get_latest_stable() {
  local repo="$1"

  # For tag-only repos, use tags API
  for t in "${TAG_ONLY_REPOS[@]}"; do
    [[ "$repo" == "$t" ]] && { get_latest_stable_tag "$repo"; return; }
  done

  # Use /releases/latest — GitHub's canonical "Latest Release" (not a
  # prerelease, not a draft). This is the green-badge release on the repo page.
  curl ${CURL_OPTS} "${GH_API}/repos/${repo}/releases/latest" 2>/dev/null \
    | python3 -c '
import json,sys
try:
    r = json.load(sys.stdin)
    print(r["tag_name"])
except: pass
' 2>/dev/null || echo ""
}

# Only for repos without GitHub Releases. Match stable version tags and filter
# out rc, beta, alpha, pre-release, test, dev, nightly, and similar prerelease
# suffixes. Also exclude tags containing "test", "nightly", "snapshot", "canary".
get_latest_stable_tag() {
  local repo="$1"
  curl ${CURL_OPTS} "${GH_API}/repos/${repo}/tags?per_page=30" 2>/dev/null \
    | python3 -c '
import json,sys,re
tags = json.load(sys.stdin)
# Suffix patterns that indicate a prerelease or unstable tag
prerelease_suffix = re.compile(
    r"[-._]?(rc|pre|alpha|beta|test|dev|nightly|snapshot|canary|preview|insider)"
    r"\d*$", re.IGNORECASE)
for t in tags:
    name = t["name"].lstrip("v")
    # Must start with a digit and be a version-like or date-based tag
    if not (re.match(r"^\d+(\.\d+)+$", name) or re.match(r"^\d{12,14}$", name)):
        continue
    # Must NOT have a prerelease suffix
    if prerelease_suffix.search(name):
        continue
    print(t["name"])
    break
' 2>/dev/null || echo ""
}

strip_prefix() {
  local ver="$1"
  [[ -n "$2" ]] && ver="${ver#"$2"}"
  echo "$ver"
}

updates_found=0

for entry in "${PKGS[@]}"; do
  IFS='|' read -r pkg repo prefix <<< "$entry"

  current=$(get_current_version "$pkg")
  [[ -z "$current" ]] && continue

  latest=$(get_latest_stable "$repo")
  [[ -z "$latest" || "$latest" == "null" ]] && continue

  cur=$(strip_prefix "$current" "$prefix")
  lat=$(strip_prefix "$latest" "$prefix")

  [[ "$cur" != "$lat" ]] || continue

  # Snapshot check: if current is 2.7.0_p20240625 and latest is v2.7.0,
  # the snapshot is git HEAD and newer than the release — skip.
  if has_snapshot "$current"; then
    cur_base=$(base_version "$cur")
    [[ "$cur_base" == "$lat" ]] && continue
  fi

  # Date-based versions (YYYYMMDDHHMMSS)
  if [[ "$cur" =~ ^[0-9]{12,14}$ ]] && [[ "$lat" =~ ^[0-9]{12,14}$ ]]; then
    [[ "$lat" -gt "$cur" ]] || continue
  fi

  updates_found=$((updates_found + 1))
  echo "UPDATE: ${pkg}: ${current} → ${latest}  (https://github.com/${repo}/releases)"
done

if [[ $updates_found -gt 0 ]]; then
  echo ""
  echo "${updates_found} package(s) have updates."
fi

exit $updates_found
