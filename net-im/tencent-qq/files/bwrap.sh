#!/bin/bash

QQ_HOTUPDATE_VERSION="__CURRENT_VER__"

function command_exists() {
    local command="$1"
    command -v "${command}" >/dev/null 2>&1
}

function show_error_dialog() {
    title="linuxqq-nt-bwrap"
    if command_exists kdialog; then
        kdialog --error "$1" --title "$title" --icon qq
    elif command_exists zenity; then
        zenity --error --title "$title" --icon-name qq --text "$1"
    else
        all_off="$(tput sgr0)"
        bold="${all_off}$(tput bold)"
        blue="${bold}$(tput setaf 4)"
        yellow="${bold}$(tput setaf 3)"
        printf "${blue}==>${yellow} ${bold} $1${all_off}\n"
    fi
}

# Check required files
if [ ! -e "/etc/localtime" ]; then
    show_error_dialog "/etc/localtime not found.\nPlease set the system timezone first."
    exit 1
fi

USER_RUN_DIR="/run/user/$(id -u)"
XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
FONTCONFIG_HOME="${XDG_CONFIG_HOME}/fontconfig"
QQ_APP_DIR="${XDG_CONFIG_HOME}/QQ"
if [ -z "${QQ_DOWNLOAD_DIR}" ]; then
    if [ -z "${XDG_DOWNLOAD_DIR}" ]; then
        XDG_DOWNLOAD_DIR="$(xdg-user-dir DOWNLOAD)"
    fi
    QQ_DOWNLOAD_DIR="${XDG_DOWNLOAD_DIR:-$HOME/Downloads}"
fi

# Load flags from config files

set -euo pipefail
electron_flags_file="${XDG_CONFIG_HOME}/qq-flags.conf"
declare -a electron_flags

if [[ -f "${electron_flags_file}" ]]; then
    mapfile -t ELECTRON_FLAGS_MAPFILE <"${electron_flags_file}"
fi

for line in "${ELECTRON_FLAGS_MAPFILE[@]}"; do
    if [[ ! "${line}" =~ ^[[:space:]]*#.* ]]; then
        electron_flags+=("${line}")
    fi
done

bwrap_flags_file="${XDG_CONFIG_HOME}/qq-bwrap-flags.conf"
declare -a bwrap_flags
if [[ -f "${bwrap_flags_file}" ]]; then
    while IFS= read -r line; do
        if [[ ! "${line}" =~ ^[[:space:]]*# ]] && [[ -n "${line}" ]]; then
            eval "expanded_line=\"$line\""
            read -ra parts <<< "$expanded_line"
            for part in "${parts[@]}"; do
                bwrap_flags+=("$part")
            done
        fi
    done < "${bwrap_flags_file}"
fi

QQ_HOTUPDATE_DIR="${QQ_APP_DIR}/versions"

# Fall back to ~/Downloads when the XDG download dir does not exist,
# to avoid mounting the whole home directory
if [ "${QQ_DOWNLOAD_DIR%*/}" == "${HOME}" ]; then
    QQ_DOWNLOAD_DIR="${HOME}/Downloads"
fi

# Register the current version
HOTUPDATE_VERSION_DIR="${QQ_HOTUPDATE_DIR}/${QQ_HOTUPDATE_VERSION}"
install -d "${QQ_HOTUPDATE_DIR}"
if [ ! -d "${HOTUPDATE_VERSION_DIR}" ] && [ ! -L "${HOTUPDATE_VERSION_DIR}" ]; then
    ln -sfd "/opt/QQ/resources/app" "${HOTUPDATE_VERSION_DIR}"
fi

# Handle old versions
rm -rf "${QQ_HOTUPDATE_DIR}/"**".zip"
is_hotupdated_version=0 # is the running version a hot-updated one?

find "${QQ_HOTUPDATE_DIR}/"*[-_]* -maxdepth 1 -type "d,l" | while read path; do
    this_version="$(basename "$path")"
    if [ "$(/opt/QQ/workarounds/vercmp.sh "${this_version}" lt "${QQ_HOTUPDATE_VERSION//_/-}")" == "true" ]; then
        # this version is older than the current one, remove it
        echo "rm $this_version"
        rm -rf "$path"
    else
        is_hotupdated_version=1
    fi
done

if [ "$is_hotupdated_version" == "0" ]; then
    cp "/opt/QQ/workarounds/config.json" "${QQ_HOTUPDATE_DIR}/config.json"
fi

bwrap --new-session --cap-drop ALL --unshare-user-try --unshare-pid --unshare-cgroup-try \
    --ro-bind /lib /lib \
    --ro-bind /lib64 /lib64 \
    --ro-bind /bin /bin \
    --ro-bind /usr /usr \
    --ro-bind /opt /opt \
    --ro-bind /opt/QQ/workarounds/xdg-open.sh /usr/bin/xdg-open \
    --ro-bind /usr/lib/snapd-xdg-open/xdg-open /snapd-xdg-open \
    --ro-bind /usr/lib/flatpak-xdg-utils/xdg-open /flatpak-xdg-open \
    --ro-bind /etc/machine-id /etc/machine-id \
    --ro-bind /etc/ld.so.cache /etc/ld.so.cache \
    --dev-bind /dev /dev \
    --ro-bind /sys /sys \
    --ro-bind /etc/passwd /etc/passwd \
    --ro-bind /etc/nsswitch.conf /etc/nsswitch.conf \
    --ro-bind-try /run/systemd/userdb /run/systemd/userdb \
    --ro-bind /etc/resolv.conf /etc/resolv.conf \
    --ro-bind /etc/localtime /etc/localtime \
    --proc /proc \
    --tmpfs "/sys/devices/virtual" \
    --dev-bind /run/dbus /run/dbus \
    --bind "${USER_RUN_DIR}" "${USER_RUN_DIR}" \
    --ro-bind-try /etc/fonts /etc/fonts \
    --dev-bind /tmp /tmp \
    --bind-try "${HOME}/.pki" "${HOME}/.pki" \
    --ro-bind-try "${XAUTHORITY}" "${XAUTHORITY}" \
    --bind-try "${QQ_DOWNLOAD_DIR}" "${QQ_DOWNLOAD_DIR}" \
    --bind "${QQ_APP_DIR}" "${QQ_APP_DIR}" \
    --ro-bind-try "${FONTCONFIG_HOME}" "${FONTCONFIG_HOME}" \
    --ro-bind-try "${HOME}/.icons" "${HOME}/.icons" \
    --ro-bind-try "${HOME}/.local/share/.icons" "${HOME}/.local/share/.icons" \
    --ro-bind-try "${XDG_CONFIG_HOME}/gtk-3.0" "${XDG_CONFIG_HOME}/gtk-3.0" \
    --ro-bind-try "${XDG_CONFIG_HOME}/dconf" "${XDG_CONFIG_HOME}/dconf" \
    --ro-bind /etc/nsswitch.conf /etc/nsswitch.conf \
    --ro-bind-try /run/systemd/userdb/ /run/systemd/userdb/ \
    --setenv IBUS_USE_PORTAL 1 \
    --setenv QQNTIM_HOME "${QQ_APP_DIR}/QQNTim" \
    "${bwrap_flags[@]}" \
    /opt/QQ/qq "${electron_flags[@]}" "$@"

# Remove useless crash reports and logs
# Comment out the following lines if you need to report bugs to Tencent
rm -rf ${QQ_APP_DIR}/crash_files
touch ${QQ_APP_DIR}/crash_files
if [ -d "${QQ_APP_DIR}/log" ]; then
    rm -rf "${QQ_APP_DIR}/log"
fi
for nt_qq_userdata in "${QQ_APP_DIR}/nt_qq_"*; do
    if [ -d "${nt_qq_userdata}/log" ]; then
        rm -rf "${nt_qq_userdata}/log"
    fi
    if [ -d "${nt_qq_userdata}/log-cache" ]; then
        rm -rf "${nt_qq_userdata}/log-cache"
    fi
done
if [ -d "${QQ_APP_DIR}/Crashpad" ]; then
    rm -rf "${QQ_APP_DIR}/Crashpad"
fi
