#!/bin/bash
# Check ruizhi-overlay packages for upstream updates.
# Only outputs results when a newer version is found.
# Usage: ./check-updates.sh [--json]
#
# Entry format: "category/package|source|version_prefix|type"
#   type=github:    source is GitHub repo (e.g. "v2fly/v2ray-core")
#   type=jetbrains: source is JetBrains product code (e.g. "DG")
#   type=scooter:   source is unused; scrapes scootersoftware.com kb/linux_install
#   type=aur:       source is AUR package name (e.g. "wps-office-cn")

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OVERLAY_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

PKGS=(
  "app-text/goldendict-ng|xiaoyifang/goldendict-ng|v|github"
  "app-text/quarto-bin|quarto-dev/quarto-cli|v|github"
  "kde-misc/latte-dock-ng|ruizhi-lab/latte-dock-ng|v|github"
  "media-fonts/sarasa-gothic|be5invis/Sarasa-Gothic|v|github"
  "media-fonts/sarasa-term-sc-nerd|laishulu/Sarasa-Term-SC-Nerd|v|github"
  "media-sound/yesplaymusic-bin|qier222/YesPlayMusic|v|github"
  "media-libs/openslide|openslide/openslide|v|github"
  "media-libs/libdicom|ImagingDataCommons/libdicom|v|github"
  "net-misc/xrdp|neutrinolabs/xrdp|v|github"
  "net-misc/xorgxrdp|neutrinolabs/xorgxrdp|v|github"
  "net-proxy/v2rayn-bin|2dust/v2rayN||github"
  "media-fonts/harmonyos-sans|ttf-harmonyos-sans||aur"
  "net-im/wechat|net-im/wechat||gentoozh"
  "dev-util/datagrip|DG||jetbrains"
  "app-misc/bcompare|bcompare||scooter"
  "app-office/wps-office|wps-office-cn||aur"
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

# Get latest version from JetBrains product API.
# Arg: product code (e.g., "DG" for DataGrip).
get_jetbrains_latest() {
  local code="$1"
  curl ${CURL_OPTS} "https://data.services.jetbrains.com/products/releases?code=${code}&latest=true&type=release" 2>/dev/null \
    | python3 -c '
import json,sys
try:
    data = json.load(sys.stdin)
    releases = data.get(sys.argv[1], [])
    if releases:
        print(releases[0]["version"])
except: pass
' "$code" 2>/dev/null || echo ""
}

# Get latest version from Scooter Software Linux install page.
# Parses download links like bcompare-X.Y.Z.BUILD (full version with build number).
get_scooter_latest() {
  curl ${CURL_OPTS} "https://www.scootersoftware.com/kb/linux_install" 2>/dev/null \
    | grep -oP 'bcompare-\K[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' 2>/dev/null \
    | sort -Vu | tail -1 || echo ""
}

# Get latest version from Arch Linux AUR.
# Arg: AUR package name (e.g., "wps-office-cn").
# Strips AUR pkgrel suffix (-1, -2, etc.) for clean version comparison.
get_aur_latest() {
  local pkgname="$1"
  curl ${CURL_OPTS} "https://aur.archlinux.org/rpc/v5/info/${pkgname}" 2>/dev/null \
    | python3 -c '
import json,sys
try:
    data = json.load(sys.stdin)
    results = data.get("results", [])
    if results:
        ver = results[0]["Version"]
        # Strip AUR pkgrel (e.g., "12.1.2.26885-1" -> "12.1.2.26885")
        ver = ver.rsplit("-", 1)[0]
        print(ver)
except: pass
' 2>/dev/null || echo ""
}

# Get latest version from gentoo-zh overlay.
# Arg: "category/package" relative path (e.g., "net-im/wechat").
# Uses GitHub API to list the package directory in gentoo-zh/overlay.
get_gentoozh_latest() {
  local pkg_path="$1"
  curl ${CURL_OPTS} "https://api.github.com/repos/gentoo-zh/overlay/contents/${pkg_path}" 2>/dev/null \
    | python3 -c '
import json,sys,re
try:
    data = json.load(sys.stdin)
    if not isinstance(data, list):
        sys.exit(0)
    versions = []
    for item in data:
        name = item["name"]
        # Match ebuild filenames: pkg-version.ebuild (skip 9999)
        m = re.match(r".+-([0-9][^-]*)\.ebuild$", name)
        if m:
            v = m.group(1).rstrip("-r1").rstrip("-r2").rstrip("-r3")
            versions.append(v)
    if versions:
        def sort_key(v):
            parts = re.split(r"[._]", v)
            try:
                return (0, tuple(int(p) for p in parts if p))
            except ValueError:
                return (1, 0)
        versions.sort(key=sort_key)
        print(versions[-1])
except: pass
' 2>/dev/null || echo ""
}

updates_found=0

for entry in "${PKGS[@]}"; do
  IFS='|' read -r pkg repo prefix type <<< "$entry"

  current=$(get_current_version "$pkg")
  [[ -z "$current" ]] && continue

  case "${type:-github}" in
    jetbrains)
      latest=$(get_jetbrains_latest "$repo")
      [[ -z "$latest" || "$latest" == "null" ]] && continue
      ;;
    scooter)
      latest=$(get_scooter_latest)
      [[ -z "$latest" ]] && continue
      ;;
    aur)
      latest=$(get_aur_latest "$repo")
      [[ -z "$latest" ]] && continue
      ;;
    gentoozh)
      latest=$(get_gentoozh_latest "$repo")
      [[ -z "$latest" ]] && continue
      ;;
    *)
      latest=$(get_latest_stable "$repo" "$current")
      [[ -z "$latest" || "$latest" == "null" ]] && continue
      ;;
  esac

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
  case "${type:-github}" in
    jetbrains)
      echo "UPDATE: ${pkg}: ${current} → ${latest}  (https://www.jetbrains.com/${pkg##*/}/download/)"
      ;;
    scooter)
      echo "UPDATE: ${pkg}: ${current} → ${latest}  (https://www.scootersoftware.com/download.php)"
      ;;
    aur)
      echo "UPDATE: ${pkg}: ${current} → ${latest}  (https://aur.archlinux.org/packages/${repo})"
      ;;
    gentoozh)
      echo "UPDATE: ${pkg}: ${current} → ${latest}  (https://github.com/gentoo-zh/overlay/tree/master/${repo})"
      ;;
    *)
      echo "UPDATE: ${pkg}: ${current} → ${latest}  (https://github.com/${repo}/tags)"
      ;;
  esac
done

if [[ $updates_found -gt 0 ]]; then
  echo ""
  echo "${updates_found} package(s) have updates."
fi

exit $updates_found
