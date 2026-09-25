# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Cockpit user interface for virtual machines"
HOMEPAGE="https://cockpit-project.org/"
SRC_URI="https://github.com/cockpit-project/${PN}/releases/download/${PV}/${P}.tar.xz"
S="${WORKDIR}/${PN}"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64 ~x86"

BDEPEND="sys-libs/libosinfo"
RDEPEND="
	>=app-admin/cockpit-${PV}
	app-emulation/libvirt-dbus
	app-emulation/libvirt[firewalld,policykit]
	app-emulation/qemu[usbredir]
	app-emulation/virt-manager[policykit]
"

src_install() {
	emake DESTDIR="${D}" PREFIX="${EPREFIX}/usr" install
}
