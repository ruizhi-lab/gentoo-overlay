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

BDEPEND="sys-devel/gettext"
# Fedora requires cockpit-bridge >= 215; Gentoo's cockpit package also ships
# the bridge. Do not tie the plugin to a matching Cockpit release number.
# libvirt-dbus is a separate service, not libvirt's own D-Bus build support.
# Upstream can fall back to virsh, but Fedora makes libvirt-dbus a hard dep;
# review this choice and the qemu/virt-manager USE mappings against Gentoo's
# current virtualization packages when those packages are updated.
RDEPEND="
	>=app-admin/cockpit-215
	>=app-emulation/libvirt-dbus-1.2.0
	app-emulation/libvirt[firewalld,policykit]
	app-emulation/qemu[usbredir]
	app-emulation/virt-manager[policykit]
"

src_install() {
	emake DESTDIR="${D}" PREFIX="${EPREFIX}/usr" install
}
