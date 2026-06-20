# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Xorg driver modules for xrdp"
HOMEPAGE="https://github.com/neutrinolabs/xorgxrdp"
SRC_URI="https://github.com/neutrinolabs/${PN}/releases/download/v${PV}/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	>=net-misc/xrdp-0.10.2
	x11-base/xorg-server:=[xorg]
"
DEPEND="${RDEPEND}"
BDEPEND="
	dev-lang/nasm
	virtual/pkgconfig
"

src_configure() {
	econf --disable-glamor
}

pkg_postinst() {
	elog "Rebuild xorgxrdp after major xorg-server upgrades if the module ABI changes."
}
