# Copyright 2023-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit unpacker desktop xdg

DESCRIPTION="Weixin for Linux"
HOMEPAGE="https://linux.weixin.qq.com"
SRC_URI="https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.deb -> wechat-${PV}_x86_64.deb"
S=${WORKDIR}

LICENSE="WeChat"

SLOT="0"
KEYWORDS="-* ~amd64"
IUSE="bwrap"

RESTRICT="strip mirror bindist"
BDEPEND="
	dev-util/patchelf
"
RDEPEND="
	app-accessibility/at-spi2-core
	virtual/krb5
	dev-libs/nss
	media-libs/libpulse
	media-libs/mesa
	net-print/cups
	virtual/jack
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libxkbcommon[X]
	x11-libs/libXrandr
	x11-libs/pango
	x11-libs/xcb-util-image
	x11-libs/xcb-util-keysyms
	x11-libs/xcb-util-renderutil
	x11-libs/xcb-util-wm
	bwrap? (
		sys-apps/bubblewrap
		x11-misc/xdg-utils
	)
"
QA_PREBUILT="*"

src_prepare() {
	default

	# add any QA scanelf alert files here.
	local so_files=(
		"RadiumWMPF/runtime/libilink2.so"
		"RadiumWMPF/runtime/libilink_network.so"
		"libilink2.so"
		"libilink_network.so"
		"libconfService.so"
		"libvoipChannel.so"
		"libvoipCodec.so"
	)

	for file in "${so_files[@]}"; do
		patchelf --set-rpath '$ORIGIN' "opt/wechat/${file}" || die
	done
}

src_install() {
	insinto /opt/wechat
	doins -r opt/wechat/* || die

	if use bwrap; then
		newbin "${FILESDIR}/bwrap.sh" wechat
		exeinto /opt/wechat
		doexe "${FILESDIR}/xdg-open.sh"
	else
		newbin "${FILESDIR}/wechat.sh" wechat
	fi

	local exec_envs=(
		"QT_AUTO_SCREEN_SCALE_FACTOR=1"
		"\"QT_QPA_PLATFORM=wayland;xcb\""
		"\"QT_IM_MODULE=${QT_IM_MODULE:-fcitx}\""
	)

	sed -i \
		-e "s|^Icon=.*|Icon=wechat|" \
		-e "s|^Categories=.*|Categories=Network;InstantMessaging;Chat;|" \
		-e "s|^Exec=.*|Exec=env ${exec_envs[*]} /usr/bin/wechat %U|" \
		usr/share/applications/wechat.desktop || die
	domenu usr/share/applications/wechat.desktop

	for size in 16 32 48 64 128 256; do
		doicon -s "${size}" usr/share/icons/hicolor/"${size}"x"${size}"/apps/wechat.png
	done
}

pkg_postinst() {
	xdg_pkg_postinst
	elog "fcitx input under Wayland: desktop file defaults to QT_IM_MODULE=fcitx."
	elog "For ibus or other IME, copy the desktop file to ~/.local/share/applications/"
	elog "and change QT_IM_MODULE accordingly."
	if use bwrap; then
		elog "Enabled Bubblewrap support."
		elog "WeChat can only access its own sandbox home and XDG Downloads directory by default."
		elog "To send files, put them under your XDG Downloads directory first, then drag"
		elog "them into WeChat or select them from WeChat's file chooser."
		elog "Advanced users can extend the sandbox using ~/.config/wechat-bwrap-flags.conf."
	fi
}
