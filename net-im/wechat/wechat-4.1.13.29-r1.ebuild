# Copyright 2023-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit unpacker desktop xdg

DESCRIPTION="Weixin for Linux"
HOMEPAGE="https://linux.weixin.qq.com"
SRC_URI="https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.deb -> wechat-${PV}_x86_64.deb"
S=${WORKDIR}

LICENSE="all-rights-reserved"

SLOT="0"
KEYWORDS="-* ~amd64"
IUSE="bwrap +fcitx ibus"

REQUIRED_USE="^^ ( fcitx ibus )"

RESTRICT="strip mirror bindist"
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

	# No ELF in the deb needs patching, so nothing here rewrites it. Every library that
	# loads a file from its own directory (libilink2, libilink_wrapper, libconfService,
	# libvoipChannel, libvoipCodec, libwxtrans) already carries $ORIGIN or ${ORIGIN}, and
	# no shipped file imports libbz2 any more. The earlier revisions rewrote those same
	# RPATHs and libwxtrans.so's libbz2.so.1.0 import with dev-util/patchelf; that never
	# fired in CI, whose image has no patchelf and where `ebuild` does not install
	# BDEPEND, so src_prepare died with "patchelf: command not found". The calls and the
	# build dependency they needed are gone, together with app-arch/bzip2, which only
	# existed for the bz2 rewrite.
}

src_install() {
	insinto /opt/wechat
	doins -r opt/wechat/* || die

	# doins doesn't set +x on executables. WeChatAppEx_sandbox is new in 4.1.13.29:
	# it is Chromium's setuid sandbox helper, shipped upstream as mode 4755. doexe installs it
	# 0755, without the setuid bit, so it can never switch to another user's credentials; it
	# starts the renderer as root only in the tree upstream builds, where no Gentoo user is.
	# Dropping the bit rather than the file keeps the program beside WeChatAppEx, which names
	# it in its own messages.
	exeinto /opt/wechat
	doexe opt/wechat/wechat opt/wechat/wxutility opt/wechat/wxplayer \
		opt/wechat/wxocr opt/wechat/crashpad_handler
	exeinto /opt/wechat/RadiumWMPF/runtime
	doexe opt/wechat/RadiumWMPF/runtime/WeChatAppEx \
		opt/wechat/RadiumWMPF/runtime/WeChatAppEx_sandbox \
		opt/wechat/RadiumWMPF/runtime/crashpad_handler

	if use bwrap; then
		newbin "${FILESDIR}/bwrap.sh" wechat
		exeinto /opt/wechat
		doexe "${FILESDIR}/xdg-open.sh"
	else
		newbin "${FILESDIR}/wechat.sh" wechat
	fi

	local ime_envs=""
	if use fcitx; then
		ime_envs=" XMODIFIERS=\"@im=fcitx\" GTK_IM_MODULE=\"fcitx\" QT_IM_MODULE=\"${QT_IM_MODULE:-fcitx}\""
	elif use ibus; then
		ime_envs=" XMODIFIERS=\"@im=ibus\" GTK_IM_MODULE=\"ibus\" QT_IM_MODULE=\"ibus\""
	fi

	local exec_cmd="Exec=env QT_AUTO_SCREEN_SCALE_FACTOR=1 QT_QPA_PLATFORM=\"wayland;xcb\""
	exec_cmd+="${ime_envs}"
	exec_cmd+=" /usr/bin/wechat %U"

	sed -i \
		-e "s|^Icon=.*|Icon=wechat|" \
		-e "s|^Categories=.*|Categories=Network;InstantMessaging;Chat;|" \
		-e "s|^Exec=.*|${exec_cmd}|" \
		usr/share/applications/wechat.desktop || die
	domenu usr/share/applications/wechat.desktop

	for size in 16 32 48 64 128 256; do
		doicon -s "${size}" usr/share/icons/hicolor/"${size}"x"${size}"/apps/wechat.png
	done
}

pkg_postinst() {
	xdg_pkg_postinst
	elog "Input method defaults to fcitx. Use USE=-fcitx ibus for ibus,"
	elog "or USE=-fcitx to disable IME variables entirely."
	if use bwrap; then
		elog "Enabled Bubblewrap support."
		elog "WeChat can only access its own sandbox home and XDG Downloads directory by default."
		elog "To send files, put them under your XDG Downloads directory first, then drag"
		elog "them into WeChat or select them from WeChat's file chooser."
		elog "Advanced users can extend the sandbox using ~/.config/wechat-bwrap-flags.conf."
	fi
}
