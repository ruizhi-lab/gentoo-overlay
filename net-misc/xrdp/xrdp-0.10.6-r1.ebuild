# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd

DESCRIPTION="Remote Desktop Protocol server"
HOMEPAGE="https://www.xrdp.org https://github.com/neutrinolabs/xrdp"
SRC_URI="https://github.com/neutrinolabs/${PN}/releases/download/v${PV}/${P}.tar.gz"

LICENSE="Apache-2.0 MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="fuse ipv6 jpeg opus +pam systemd"

RDEPEND="
	dev-libs/openssl:0=
	x11-libs/libX11
	x11-libs/libXfixes
	x11-libs/libXrandr
	fuse? ( sys-fs/fuse:3 )
	jpeg? ( media-libs/libjpeg-turbo:= )
	opus? ( media-libs/opus )
	pam? ( sys-libs/pam )
	systemd? ( sys-apps/systemd )
"
DEPEND="${RDEPEND}"
BDEPEND="virtual/pkgconfig"

src_configure() {
	local myeconfargs=(
		$(use_enable fuse)
		$(use_enable ipv6)
		$(use_enable jpeg)
		$(use_enable jpeg tjpeg)
		$(use_enable opus)
		$(use_enable pam)
		$(use_with systemd systemdsystemunitdir "$(systemd_get_systemunitdir)")
		--with-pamconfdir="${EPREFIX}"/etc/pam.d
	)

	econf "${myeconfargs[@]}"
}

pkg_postinst() {
	elog "xrdp installed. Enable and start the xrdp service if needed."
}
