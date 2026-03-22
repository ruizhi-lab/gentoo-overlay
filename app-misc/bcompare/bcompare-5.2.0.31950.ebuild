# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit xdg-utils

DESCRIPTION="Compare, merge files and folders using simple, powerful commands."
HOMEPAGE="https://www.scootersoftware.com"
SRC_URI="https://www.scootersoftware.com/${P}.x86_64.tar.gz"

LICENSE="Bcompare"
SLOT="0"
KEYWORDS="amd64"
IUSE=""
QA_PREBUILT="*"

RESTRICT="bindist mirror"

DEPEND=""
RDEPEND="
	app-arch/bzip2
	app-arch/p7zip
	app-arch/unrar
	dev-libs/libqt6pas
	dev-qt/qtbase:6[gui,widgets]
	sys-apps/dbus
	sys-libs/zlib
	x11-libs/libX11
	x11-libs/libxkbcommon
	"
BDEPEND=""

src_install()
{
	mkdir -p "${D}/"usr/lib/beyondcompare
	cp "${S}/"{BCompare,BCompare.mad,libcloudstorage.so.22.0} "${D}/"usr/lib/beyondcompare/

	ln -s /usr/lib64/p7zip/7z.so "${D}/"usr/lib/beyondcompare/lib7z.so

	mkdir -p "${D}/"usr/bin
	cat <<-EOF >"${D}"/usr/bin/bcompare || die
		#!/bin/sh
		LD_LIBRARY_PATH="/usr/lib/beyondcompare" \\
		exec /usr/lib/beyondcompare/BCompare "\$@"
	EOF
	fperms +x /usr/bin/bcompare

	mkdir -p "${D}/"usr/share/applications
	cp "${S}/"bcompare.desktop "${D}/"usr/share/applications/

	mkdir -p "${D}/"usr/share/doc/${PF}
	cp -r "${S}/"help/* "${D}/"usr/share/doc/${PF}/

	mkdir -p "${D}/"usr/share/mime/packages
	cp "${S}/"bcompare.xml "${D}/"usr/share/mime/packages/

	mkdir -p "${D}/"usr/share/pixmaps
	cp "${S}/"{bcompare.png,bcomparefull32.png,bcomparehalf32.png} "${D}/"usr/share/pixmaps/

	# prevent revdep-rebuild from attempting to rebuild all the time
	insinto /etc/revdep-rebuild
	echo "SEARCH_DIRS_MASK=\"/usr/lib/beyondcompare\"" >> ${T}/20${PN}
	doins "${T}/20${PN}"
}

pkg_postinst() {
	xdg_desktop_database_update
	xdg_mimeinfo_database_update
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_mimeinfo_database_update
}

