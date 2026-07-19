#!/bin/bash
# Check ruizhi-overlay packages for upstream updates.
# Only outputs results when a newer version is found.
# Usage: ./check-updates.sh [--json]
#
# Entry format: "category/package|github_repo|version_prefix"
#
# Uses releases API with prerelease/draft filtering. Falls back to tags API
# for repos that don't create GitHub Releases or where all releases are prerelease.

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
  "kde-misc/latte-dock-ng|ruizhi-lab/latte-dock-ng|v"
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

GH_API="${GITHUB_API_URL:-https://api.github.com}"
CURL_OPTS="${CURL_OPTS:--s}"
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  CURL_OPTS="$CURL_OPTS -H \"Authorization: Bearer ${GITHUB_TOKEN}\""
fi
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

# Get the latest stable version from GitHub.
# 1. Try releases API — filter out prerelease and draft, pick the first one.
#    This is authoritative because maintainers set the prerelease checkbox.
# 2. If no stable release found, or the latest stable release is older than
#    the current version (upstream stopped creating releases), fall back to
#    tags API with prerelease-suffix filtering.
get_latest_stable() {
  local repo="$1"
  local current_ver="${2:-}"

  # Fetch releases list, pick first non-prerelease, non-draft
  local latest
  latest=$(curl ${CURL_OPTS} "${GH_API}/repos/${repo}/releases?per_page=30" 2>/dev/null \
    | python3 -c '
import json,sys
try:
    releases = json.load(sys.stdin)
    if not isinstance(releases, list):
        sys.exit(0)
    for r in releases:
        if not r.get("prerelease") and not r.get("draft"):
            print(r["tag_name"])
            break
except: pass
' 2>/dev/null || echo "")

  # If no stable release at all, fall back to tags
  if [[ -z "$latest" ]]; then
    latest=$(get_latest_tag "$repo")
    echo "$latest"
    return
  fi

  # If latest stable release is older than our current version,
  # upstream may not create releases for newer tags. Try tags.
  if [[ -n "$current_ver" ]]; then
    local rel_ver="${latest#v}"
    local cur_ver="${current_ver#v}"
    if [[ "$rel_ver" != "$cur_ver" ]]; then
      local oldest
      oldest=$(printf '%s\n%s\n' "$rel_ver" "$cur_ver" | sort -V | head -1)
      if [[ "$oldest" == "$rel_ver" ]]; then
        local tag_latest
        tag_latest=$(get_latest_tag "$repo")
        [[ -n "$tag_latest" ]] && { echo "$tag_latest"; return; }
      fi
    fi
  fi

  echo "$latest"
}

# Fallback for repos without GitHub Releases, or where all releases are
# prerelease. Fetches up to 100 tags, filters by version pattern, excludes
# known unstable suffixes (rc, beta, alpha, etc.), and picks the highest.
get_latest_tag() {
  local repo="$1"
  curl ${CURL_OPTS} "${GH_API}/repos/${repo}/tags?per_page=100" 2>/dev/null \
    | python3 -c '
import json,sys,re
tags = json.load(sys.stdin)
if not isinstance(tags, list):
    sys.exit(0)

prerelease_word = re.compile(
    r"(?:^|[._+-])(rc|pre|alpha|beta|test|dev|nightly|snapshot|canary|preview"
    r"|insider|prerelease|unstable|experimental|wip|draft|early|next)"
    r"\d*$", re.IGNORECASE)

stable = []
for t in tags:
    name = t["name"]
    stripped = name.lstrip("v")
    if not (re.match(r"^\d+(\.\d+)+$", stripped) or re.match(r"^\d{12,14}$", stripped)):
        continue
    if prerelease_word.search(stripped):
        continue
    stable.append(stripped)

if stable:
    def sort_key(v):
        parts = v.split(".")
        try:
            return (0, tuple(int(p) for p in parts))
        except ValueError:
            return (1, int(v))
    stable.sort(key=sort_key)
    print(stable[-1])
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

  latest=$(get_latest_stable "$repo" "$current")
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
  echo "UPDATE: ${pkg}: ${current} → ${latest}  (https://github.com/${repo}/tags)"
done

if [[ $updates_found -gt 0 ]]; then
  echo ""
  echo "${updates_found} package(s) have updates."
fi

exit $updates_found
