# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit meson

DESCRIPTION="D-Bus API for libvirt"
HOMEPAGE="https://libvirt.org/dbus.html"
SRC_URI="https://download.libvirt.org/dbus/${P}.tar.xz"

LICENSE="LGPL-2.1+"
SLOT="0"
KEYWORDS="~amd64 ~x86"

BDEPEND="
	dev-python/docutils
	virtual/pkgconfig
"
# These minimum versions are taken from the upstream Meson build files.
DEPEND="
	>=app-emulation/libvirt-3.0.0
	>=app-emulation/libvirt-glib-0.0.7
	>=dev-libs/glib-2.44.0
"
RDEPEND="${DEPEND}
	acct-user/libvirtdbus
	sys-apps/dbus
	sys-auth/polkit
"

src_configure() {
	local emesonargs=(
		# Use D-Bus activation without requiring systemd on OpenRC systems.
		-Dinit_script=other
		-Dsystem_user=libvirtdbus
		-Dunix_socket_group=libvirt
	)
	meson_src_configure
}
