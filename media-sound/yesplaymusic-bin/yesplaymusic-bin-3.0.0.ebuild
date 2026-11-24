# Copyright 2023-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop xdg

DESCRIPTION="Desktop music player with a plugin system"
HOMEPAGE="https://github.com/qier222/YesPlayMusic"
SRC_URI="https://github.com/qier222/YesPlayMusic/releases/download/v${PV}/YesPlayMusic-${PV}-linux-x64.tar.gz -> ${P}.tar.gz"

S="${WORKDIR}/YesPlayMusic-${PV}-linux-x64"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="-* ~amd64"

# Upstream ships the Flutter AOT snapshot (libapp.so) prebuilt; leave it as built
RESTRICT="mirror strip"

QA_PREBUILT="
	opt/YesPlayMusic/yesplaymusic
	opt/YesPlayMusic/lib/*
"

# 3.0.0 is a Flutter rewrite that plays audio through media_kit, which loads libmpv at run time.
RDEPEND="
	media-video/mpv[libmpv]
	x11-libs/gtk+:3"

src_install() {
	insinto /opt/YesPlayMusic
	doins -r yesplaymusic lib data
	fperms 0755 /opt/YesPlayMusic/yesplaymusic

	dosym ../../opt/YesPlayMusic/yesplaymusic /usr/bin/yesplaymusic

	doicon -s 512 yesplaymusic.png
	domenu yesplaymusic.desktop
}

pkg_postinst() {
	xdg_pkg_postinst
}
