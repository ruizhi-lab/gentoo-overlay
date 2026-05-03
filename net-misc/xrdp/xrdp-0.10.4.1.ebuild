# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Remote Desktop Protocol server"
HOMEPAGE="https://www.xrdp.org https://github.com/neutrinolabs/xrdp"
SRC_URI="https://github.com/neutrinolabs/${PN}/releases/download/v${PV}/${P}.tar.gz"

LICENSE="Apache-2.0 MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	dev-libs/openssl:0=
	sys-libs/pam
	x11-libs/libX11
	x11-libs/libXfixes
"
DEPEND="${RDEPEND}"
BDEPEND="virtual/pkgconfig"

src_configure() {
	econf \
		--enable-pam \
		--with-pamconfdir="${EPREFIX}"/etc/pam.d
}

pkg_postinst() {
	elog "xrdp installed. Enable and start the xrdp service if needed."
}
