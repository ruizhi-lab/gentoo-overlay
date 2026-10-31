#!/bin/bash
# Check ruizhi-overlay packages for upstream updates.
# Only outputs results when a newer version is found.
# Usage: ./check-updates.sh [--json]
#
# Entry format: "category/package|source|version_prefix|type"
#   type=github:    source is GitHub repo (e.g. "owner/repository")
#   type=github-date-hyphen: GitHub tag YYYYMMDD-N maps to Gentoo YYYYMMDD.N
#   type=github-kwin-glass: KWin Glass tag YYYYMMDD-6.8.0-support maps to
#                           Gentoo YYYYMMDD.6.8.0
#   type=github-prism-build: Prism tag prism-bN-<commit> maps to Gentoo N
#   type=jetbrains: source is JetBrains product code (e.g. "DG")
#   type=scooter:   source is unused; scrapes scootersoftware.com kb/linux_install
#   type=aur:       source is AUR package name (e.g. "wps-office-cn")
#   type=openai-deb: source is the OpenAI Debian Packages index
#   type=claude-deb: source is the Claude Desktop Debian Packages index
#   type=comfy-pin: source is a project name pinned with "==" in the
#                   requirements.txt of the latest ComfyUI release
#   type=comfy-pin-sub: source is a PyPI project name pinned with "==" by the
#                       comfyui-workflow-templates release that ComfyUI pins
#
# A lookup that fails, or finds no version, is reported as a "::error::" line on
# stderr and that entry is skipped. The exit status is the number of UPDATE lines.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OVERLAY_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

PKGS=(
  "app-text/goldendict-ng|xiaoyifang/goldendict-ng||github-goldendict"
  "app-text/quarto-bin|quarto-dev/quarto-cli|v|github"
  "kde-misc/latte-dock-ng|ruizhi-lab/latte-dock-ng|v|github"
  "kde-misc/kwin-effects-glass|4v3ngR/kwin-effects-glass||github-kwin-glass"
  "media-fonts/sarasa-gothic|be5invis/Sarasa-Gothic|v|github"
  "media-fonts/sarasa-term-sc-nerd|laishulu/Sarasa-Term-SC-Nerd|v|github"
  "media-sound/sidra-bin|wimpysworld/sidra||github"
  "media-sound/yesplaymusic-bin|qier222/YesPlayMusic|v|github"
  "x11-themes/colloid-icon-theme|vinceliuice/Colloid-icon-theme||github-date-iso"
  "x11-themes/tela-icon-theme|vinceliuice/Tela-icon-theme||github-date-iso"
  "net-misc/xrdp|neutrinolabs/xrdp|v|github"
  "net-proxy/v2rayn-bin|2dust/v2rayN||github"
  "net-misc/xorgxrdp|neutrinolabs/xorgxrdp|v|github"
  "dev-python/kornia-rs|kornia/kornia-rs|v|github"
  "media-gfx/comfyui|Comfy-Org/ComfyUI|v|github"
  # ComfyUI's asset packages follow the exact pins in its requirements.txt, so
  # they are compared with those pins rather than with the newest upstream release.
  "dev-python/comfy-aimdo|comfy-aimdo||comfy-pin"
  "dev-python/comfy-kitchen|comfy-kitchen||comfy-pin"
  "dev-python/comfyui-embedded-docs|comfyui-embedded-docs||comfy-pin"
  "dev-python/comfyui-frontend-package|comfyui-frontend-package||comfy-pin"
  "dev-python/comfyui-workflow-templates|comfyui-workflow-templates||comfy-pin"
  # The workflow-templates sub-packages are pinned by the comfyui-workflow-templates
  # release that ComfyUI pins, so they are compared with that release's requirements.
  "dev-python/comfyui-workflow-templates-core|comfyui-workflow-templates-core||comfy-pin-sub"
  "dev-python/comfyui-workflow-templates-json|comfyui-workflow-templates-json||comfy-pin-sub"
  "dev-python/comfyui-workflow-templates-media-api|comfyui-workflow-templates-media-api||comfy-pin-sub"
  "dev-python/comfyui-workflow-templates-media-video|comfyui-workflow-templates-media-video||comfy-pin-sub"
  "dev-python/comfyui-workflow-templates-media-image|comfyui-workflow-templates-media-image||comfy-pin-sub"
  "dev-python/comfyui-workflow-templates-media-other|comfyui-workflow-templates-media-other||comfy-pin-sub"
  "dev-python/comfyui-workflow-templates-media-assets-one|comfyui-workflow-templates-media-assets-01||comfy-pin-sub"
  "dev-python/comfyui-workflow-templates-media-assets-two|comfyui-workflow-templates-media-assets-02||comfy-pin-sub"
  "sci-ml/einops|arogozhnikov/einops|v|github"
  "sci-ml/kornia|kornia/kornia|v|github"
  "sci-ml/spandrel|chaiNNer-org/spandrel|v|github"
  "sci-ml/strata|Niko1221/Strata|v|github"
  "sci-ml/torchaudio|pytorch/audio|v|github"
  "sci-ml/torchsde|google-research/torchsde|v|github"
  "media-fonts/harmonyos-sans|ttf-harmonyos-sans||aur"
  "net-im/wechat|net-im/wechat||gentoozh"
  "net-misc/baidunetdisk|net-misc/baidunetdisk||gentoozh"
  "dev-util/datagrip|DG||jetbrains"
  "app-misc/bcompare|bcompare||scooter"
  "app-admin/cockpit|cockpit-project/cockpit||github"
  "app-admin/cockpit-machines|cockpit-project/cockpit-machines||github"
  "sci-misc/prism-llama-cpp|PrismML-Eng/llama.cpp||github-prism-build"
  "sci-misc/kvmem-llama-cpp|kvmem/kvmem|v|github"
  "app-office/wps-office|wps-office-cn||aur"
  "app-misc/chatgpt-desktop|https://persistent.oaistatic.com/codex-app-prod/linux/deb/dists/stable/main/binary-amd64/Packages||openai-deb"
  "app-misc/claude-desktop|https://downloads.claude.ai/claude-desktop/apt/stable/dists/stable/main/binary-amd64/Packages||claude-deb"
)

GH_API="${GITHUB_API_URL:-https://api.github.com}"
# Every request follows redirects (repositories get renamed), fails on HTTP
# errors, and gives up after 60 seconds, so a bad response is reported by the
# caller instead of being parsed as empty output.
CURL_ARGS=(-fsL --connect-timeout 20 --max-time 60)
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  CURL_ARGS+=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
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
# Exit status 1 means a request failed; an empty result means no version found.
get_latest_stable() {
  local repo="$1"
  local current_ver="${2:-}"

  # Fetch releases list, pick first non-prerelease, non-draft
  # Upstream sometimes publishes an rc as a plain release (kvmem marks
  # v0.19.0-rc1 as a release), so the version itself is filtered too, the same
  # way get_latest_tag filters tags.
  local latest
  latest=$(curl "${CURL_ARGS[@]}" "${GH_API}/repos/${repo}/releases?per_page=30" \
    | python3 -c '
import json,re,sys
releases = json.load(sys.stdin)
if not isinstance(releases, list):
    sys.exit(1)
prerelease_word = re.compile(
    r"(?:^|[._+-])(rc|pre|alpha|beta|test|dev|nightly|snapshot|canary|preview"
    r"|insider|prerelease|unstable|experimental|wip|draft|early|next)"
    r"\d*$", re.IGNORECASE)
for r in releases:
    if r.get("prerelease") or r.get("draft"):
        continue
    if prerelease_word.search(r.get("tag_name", "").lstrip("v")):
        continue
    print(r["tag_name"])
    break
' 2>/dev/null) || return 1

  # If no stable release at all, fall back to tags
  if [[ -z "$latest" ]]; then
    get_latest_tag "$repo" || return 1
    return 0
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
        tag_latest=$(get_latest_tag "$repo") || return 1
        if [[ -n "$tag_latest" ]]; then
          echo "$tag_latest"
          return 0
        fi
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
  curl "${CURL_ARGS[@]}" "${GH_API}/repos/${repo}/tags?per_page=100" \
    | python3 -c '
import json,sys,re
tags = json.load(sys.stdin)
if not isinstance(tags, list):
    sys.exit(1)

prerelease_word = re.compile(
    r"(?:^|[._+-])(rc|pre|alpha|beta|test|dev|nightly|snapshot|canary|preview"
    r"|insider|prerelease|unstable|experimental|wip|draft|early|next)"
    r"\d*$", re.IGNORECASE)

stable = []
for t in tags:
    name = t["name"]
    stripped = name.lstrip("v")
    if not (re.match(r"^\d+(\.\d+)+$", stripped)
            or re.match(r"^\d{12,14}$", stripped)
            or re.match(r"^\d{8}-\d+$", stripped)
            or re.match(r"^\d{8}-\d+(?:\.\d+)*-support$", stripped)):
        continue
    if prerelease_word.search(stripped):
        continue
    stable.append(stripped)

if stable:
    def sort_key(v):
        parts = [p for p in re.split(r"[.-]", v) if p != "support"]
        return tuple(int(p) for p in parts)
    stable.sort(key=sort_key)
    print(stable[-1])
' 2>/dev/null
}

# GoldenDict-ng also publishes vcpkg export archives and daily builds as
# GitHub releases. Its Gentoo release version is the numeric component of the
# stable `vX.Y.Z-Release.<commit>` tag, so ignore development-only releases.
get_goldendict_latest() {
  local repo="$1"
  curl "${CURL_ARGS[@]}" "${GH_API}/repos/${repo}/releases?per_page=100" \
    | python3 -c '
import json,re,sys
releases = json.load(sys.stdin)
if not isinstance(releases, list):
    sys.exit(1)
for release in releases:
    if release.get("prerelease") or release.get("draft"):
        continue
    match = re.fullmatch(r"v?(\d+\.\d+\.\d+)-Release\.[0-9a-fA-F]+", release.get("tag_name", ""))
    if match:
        print(match.group(1))
        break
' 2>/dev/null
}

# Print "name version" for every exact pin in a ComfyUI release's requirements.txt.
# Names are normalized the way PyPI does (lowercase, runs of -_. become "-").
get_comfy_pins() {
  curl "${CURL_ARGS[@]}" "https://raw.githubusercontent.com/Comfy-Org/ComfyUI/$1/requirements.txt" \
    | python3 -c '
import re,sys
for line in sys.stdin:
    m = re.fullmatch(r"([A-Za-z0-9._-]+)==([0-9][0-9A-Za-z.+!_-]*)\s*(#.*)?", line.strip())
    if m:
        print(re.sub(r"[-_.]+", "-", m.group(1)).lower(), m.group(2))
' 2>/dev/null
}

# Print "name version" for every unconditional exact pin that a PyPI release declares.
get_pypi_requires_pins() {
  curl "${CURL_ARGS[@]}" "https://pypi.org/pypi/$1/$2/json" \
    | python3 -c '
import json,re,sys
for req in json.load(sys.stdin)["info"].get("requires_dist") or []:
    if ";" in req:
        continue
    m = re.fullmatch(r"\s*([A-Za-z0-9._-]+)==([0-9][0-9A-Za-z.+!_-]*)\s*", req)
    if m:
        print(re.sub(r"[-_.]+", "-", m.group(1)).lower(), m.group(2))
' 2>/dev/null
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
  curl "${CURL_ARGS[@]}" "https://data.services.jetbrains.com/products/releases?code=${code}&latest=true&type=release" \
    | python3 -c '
import json,sys
data = json.load(sys.stdin)
releases = data.get(sys.argv[1], [])
if releases:
    print(releases[0]["version"])
' "$code" 2>/dev/null
}

# Get latest version from Scooter Software Linux install page.
# Parses download links like bcompare-X.Y.Z.BUILD (full version with build number).
# The site's WAF answers HTTP 500 to curl's default User-Agent, so the page is
# requested as a browser does.
get_scooter_latest() {
  local page
  page=$(curl "${CURL_ARGS[@]}" \
    -A "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36" \
    "https://www.scootersoftware.com/kb/linux_install") || return 1
  printf '%s\n' "$page" | { grep -oP 'bcompare-\K[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' || true; } \
    | sort -Vu | tail -1
}

# Get latest version from Arch Linux AUR.
# Arg: AUR package name (e.g., "wps-office-cn").
# Strips AUR pkgrel suffix (-1, -2, etc.) for clean version comparison.
get_aur_latest() {
  local pkgname="$1"
  curl "${CURL_ARGS[@]}" "https://aur.archlinux.org/rpc/v5/info/${pkgname}" \
    | python3 -c '
import json,sys
results = json.load(sys.stdin).get("results", [])
if results:
    # Strip AUR pkgrel (e.g., "12.1.2.26885-1" -> "12.1.2.26885")
    print(results[0]["Version"].rsplit("-", 1)[0])
' 2>/dev/null
}

# Get latest version from gentoo-zh overlay.
# Arg: "category/package" relative path (e.g., "net-im/wechat").
# Uses GitHub API to list the package directory in gentoo-zh/overlay.
get_gentoozh_latest() {
  local pkg_path="$1"
  curl "${CURL_ARGS[@]}" "https://api.github.com/repos/gentoo-zh/overlay/contents/${pkg_path}" \
    | python3 -c '
import json,re,sys
data = json.load(sys.stdin)
if not isinstance(data, list):
    sys.exit(1)
versions = []
for item in data:
    # Match ebuild filenames: pkg-version[-rN].ebuild (skip 9999)
    m = re.match(r".+-([0-9][^-]*?)(?:-r[0-9]+)?\.ebuild$", item["name"])
    if m and "9999" not in m.group(1):
        versions.append(m.group(1))
if versions:
    def sort_key(v):
        parts = re.split(r"[._]", v)
        try:
            return (0, tuple(int(p) for p in parts if p))
        except ValueError:
            return (1, 0)
    versions.sort(key=sort_key)
    print(versions[-1])
' 2>/dev/null
}

# Get the latest ChatGPT Desktop version from OpenAI's Debian repository.
# The amd64 Packages index is sufficient because both supported architectures
# are published from the same release stream. The index is read to the end so
# that curl never writes into a pipe that awk has already closed.
get_openai_deb_latest() {
  curl "${CURL_ARGS[@]}" "$1" \
    | awk '/^Package: chatgpt$/{found=1; next} found && /^Package:/{found=0} found && /^Version:/ && !done {print $2; done=1}'
}

# Claude's Packages index retains older releases, so select the highest version.
get_claude_deb_latest() {
  curl "${CURL_ARGS[@]}" "$1" \
    | awk '/^Package: claude-desktop$/{found=1; next} found && /^Version:/{print $2; found=0}' \
    | sort -V | tail -1
}

# Pins that ComfyUI's latest release sets for its asset packages. They are loaded
# once, so every comfy-pin entry compares against the same release. A failure is
# recorded in the *_PIN_ERROR variables and reported for each dependent entry.
declare -A COMFY_PINS=() SUB_PINS=()
COMFY_REF=""
COMFY_PIN_ERROR=""
SUB_PIN_ERROR=""

load_comfy_pins() {
  local tag pins name version wt_version
  if ! tag=$(get_latest_stable "Comfy-Org/ComfyUI") || [[ -z "$tag" ]]; then
    COMFY_PIN_ERROR="could not resolve the latest ComfyUI release"
    return 0
  fi
  if ! pins=$(get_comfy_pins "$tag") || [[ -z "$pins" ]]; then
    COMFY_PIN_ERROR="could not read requirements.txt of ComfyUI ${tag}"
    return 0
  fi
  while read -r name version; do
    COMFY_PINS[$name]=$version
  done <<< "$pins"
  COMFY_REF=$tag

  wt_version="${COMFY_PINS[comfyui-workflow-templates]:-}"
  if [[ -z "$wt_version" ]]; then
    SUB_PIN_ERROR="ComfyUI ${tag} does not pin comfyui-workflow-templates"
    return 0
  fi
  if ! pins=$(get_pypi_requires_pins comfyui-workflow-templates "$wt_version") || [[ -z "$pins" ]]; then
    SUB_PIN_ERROR="could not read the requirements of comfyui-workflow-templates ${wt_version}"
    return 0
  fi
  while read -r name version; do
    SUB_PINS[$name]=$version
  done <<< "$pins"
}

# Print the latest upstream version for one entry. Exit status 1 means the
# upstream request failed; empty output means no version was found.
lookup_latest() {
  local type="$1" repo="$2" current="$3"
  case "$type" in
    jetbrains)         get_jetbrains_latest "$repo" ;;
    scooter)           get_scooter_latest ;;
    aur)               get_aur_latest "$repo" ;;
    gentoozh)          get_gentoozh_latest "$repo" ;;
    openai-deb)        get_openai_deb_latest "$repo" ;;
    claude-deb)        get_claude_deb_latest "$repo" ;;
    comfy-pin)         printf '%s\n' "${COMFY_PINS[$repo]:-}" ;;
    comfy-pin-sub)     printf '%s\n' "${SUB_PINS[$repo]:-}" ;;
    github-goldendict) get_goldendict_latest "$repo" ;;
    github-date-hyphen)
      # Compare release tags in their upstream form so an equal release does
      # not look older than the Gentoo-normalized PV and trigger a tags
      # fallback. For example, 20260620.1 maps back to 20260620-1.
      get_latest_stable "$repo" "${current/./-}" ;;
    github-kwin-glass)
      get_latest_stable "$repo" "${current%%.*}-${current#*.}-support" ;;
    github-prism-build)
      get_latest_stable "$repo" "$current" ;;
    github-date-iso)
      # The current PV is YYYYMMDD but the release tag is YYYY-MM-DD; avoid
      # the helper's generic current-version fallback comparison here.
      get_latest_stable "$repo" ;;
    *)
      get_latest_stable "$repo" "$current" ;;
  esac
}

updates_found=0
lookup_errors=0

# Report a lookup that failed or found nothing. The ::error:: prefix makes GitHub
# Actions show it as an annotation. The entry is skipped, never reported as current.
lookup_error() {
  lookup_errors=$((lookup_errors + 1))
  echo "::error::check-updates: $1: $2" >&2
}

load_comfy_pins

for entry in "${PKGS[@]}"; do
  IFS='|' read -r pkg repo prefix type <<< "$entry"
  type="${type:-github}"

  current=$(get_current_version "$pkg" || true)
  if [[ -z "$current" ]]; then
    lookup_error "$pkg" "no release ebuild found in the overlay"
    continue
  fi

  case "$type" in
    comfy-pin)     pin_error="$COMFY_PIN_ERROR" ;;
    comfy-pin-sub) pin_error="${COMFY_PIN_ERROR:-$SUB_PIN_ERROR}" ;;
    *)             pin_error="" ;;
  esac
  if [[ -n "$pin_error" ]]; then
    lookup_error "$pkg" "$pin_error"
    continue
  fi

  if ! latest=$(lookup_latest "$type" "$repo" "$current"); then
    lookup_error "$pkg" "could not query the ${type} source ${repo}"
    continue
  fi
  if [[ -z "$latest" || "$latest" == "null" ]]; then
    lookup_error "$pkg" "no version found for ${repo}"
    continue
  fi

  if [[ "$type" == "github-prism-build" ]]; then
    cur="$current"
    if [[ "$latest" =~ ^prism-b([0-9]+)-[[:xdigit:]]+$ ]]; then
      lat="${BASH_REMATCH[1]}"
    else
      lookup_error "$pkg" "unrecognised Prism tag ${latest}"
      continue
    fi
  else
    cur=$(strip_prefix "$current" "$prefix")
    lat=$(strip_prefix "$latest" "$prefix")
  fi

  # Gentoo versions cannot represent an upstream release counter with a
  # hyphen because that syntax is reserved for ebuild revisions. Map tags such
  # as 20260620-1 to the corresponding Gentoo PV 20260620.1 for comparison.
  if [[ "$type" == "github-date-hyphen" ]]; then
    lat="${lat/-/.}"
  fi

  if [[ "$type" == "github-kwin-glass" ]]; then
    if [[ "$lat" =~ ^([0-9]{8})-([0-9]+(\.[0-9]+)*)-support$ ]]; then
      lat="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
    else
      lookup_error "$pkg" "unrecognised KWin Glass tag ${latest}"
      continue
    fi
  fi

  # Upstream tags use YYYY-MM-DD while the ebuild PV uses Gentoo's YYYYMMDD.
  if [[ "$type" == "github-date-iso" ]]; then
    lat="${lat//-/}"
  fi

  # Report only when upstream is strictly newer. Sources can lag behind
  # (e.g. a stale AUR package); comparing for inequality would then
  # emit downgrade alerts.
  if [[ "$cur" == "$lat" ]]; then
    continue
  fi
  if [[ "$(printf '%s\n%s\n' "$cur" "$lat" | sort -V | tail -1)" == "$cur" ]]; then
    continue
  fi

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
  case "$type" in
    jetbrains)
      echo "UPDATE: ${pkg}: ${current} -> ${latest}  (https://www.jetbrains.com/${pkg##*/}/download/)"
      ;;
    scooter)
      echo "UPDATE: ${pkg}: ${current} -> ${latest}  (https://www.scootersoftware.com/download.php)"
      ;;
    aur)
      echo "UPDATE: ${pkg}: ${current} -> ${latest}  (https://aur.archlinux.org/packages/${repo})"
      ;;
    gentoozh)
      echo "UPDATE: ${pkg}: ${current} -> ${latest}  (https://github.com/gentoo-zh/overlay/tree/master/${repo})"
      ;;
    openai-deb|claude-deb)
      echo "UPDATE: ${pkg}: ${current} -> ${latest}  (${repo})"
      ;;
    comfy-pin)
      echo "UPDATE: ${pkg}: ${current} -> ${latest}  (https://github.com/Comfy-Org/ComfyUI/blob/${COMFY_REF}/requirements.txt)"
      ;;
    comfy-pin-sub)
      echo "UPDATE: ${pkg}: ${current} -> ${latest}  (pinned by comfyui-workflow-templates ${COMFY_PINS[comfyui-workflow-templates]} in ComfyUI ${COMFY_REF})"
      ;;
    *)
      echo "UPDATE: ${pkg}: ${current} -> ${latest}  (https://github.com/${repo}/tags)"
      ;;
  esac
done

if [[ $lookup_errors -gt 0 ]]; then
  echo "check-updates: ${lookup_errors} lookup(s) failed; the entries reported above were not checked." >&2
fi

if [[ $updates_found -gt 0 ]]; then
  echo ""
  echo "${updates_found} package(s) have updates."
fi

exit $updates_found
