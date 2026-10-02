# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop optfeature pax-utils unpacker xdg

DESCRIPTION="Apple Music desktop client with Widevine DRM and MPRIS integration"
HOMEPAGE="https://github.com/wimpysworld/sidra"
SRC_URI="
	amd64? ( https://github.com/wimpysworld/sidra/releases/download/${PV}/Sidra-${PV}-linux-amd64.deb )
	arm64? ( https://github.com/wimpysworld/sidra/releases/download/${PV}/Sidra-${PV}-linux-arm64.deb )
"
S="${WORKDIR}"

LICENSE="BlueOak-1.0.0 MIT BSD"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"
RESTRICT="mirror strip"

RDEPEND="
	app-accessibility/at-spi2-core:2
	app-crypt/libsecret
	app-misc/ca-certificates
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/mesa[gbm(+)]
	net-print/cups
	sys-apps/dbus
	sys-apps/util-linux
	virtual/libudev
	x11-libs/cairo
	x11-libs/gtk+:3
	x11-libs/libnotify
	x11-libs/libX11
	x11-libs/libxcb
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libxkbcommon
	x11-libs/libXrandr
	x11-libs/libXScrnSaver
	x11-libs/libXtst
	x11-libs/pango
	x11-misc/xdg-utils
"

QA_PREBUILT="*"

src_install() {
	dodir /opt
	mv opt/Sidra "${ED}/opt/sidra" || die

	fperms 4755 /opt/sidra/chrome-sandbox
	pax-mark m "${ED}/opt/sidra/sidra"

	exeinto /usr/bin
	newexe "${FILESDIR}/sidra" sidra
	domenu "${FILESDIR}/sidra.desktop"
	insinto /usr/share/icons
	doins -r usr/share/icons/hicolor
}

pkg_postinst() {
	xdg_pkg_postinst

	optfeature "system tray integration" dev-libs/libayatana-appindicator
	elog "An Apple Music subscription is required for playback."
	elog "CastLabs Electron downloads the Widevine CDM on first use."
}
