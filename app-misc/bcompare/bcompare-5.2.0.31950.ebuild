# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop xdg-utils

DESCRIPTION="Compare, merge files and folders using simple, powerful commands."
HOMEPAGE="https://www.scootersoftware.com"
SRC_URI="https://www.scootersoftware.com/${P}.x86_64.tar.gz"

LICENSE="Bcompare"
SLOT="0"
KEYWORDS="amd64"
IUSE=""
QA_PREBUILT="*"

RESTRICT="bindist mirror strip"

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

src_install() {
	local BC_LIB="/usr/lib/beyondcompare"
    local BC_BIN="/usr/bin"

    exeinto "${BC_LIB}"
    doexe BCompare bcmount.sh

    insinto "${BC_LIB}"
    doins BCompare.mad lib7z.so libcloudstorage.so.22.0 libunrar.so
    doins bcompare.conf.sample mime.types README copyright

    dosym /usr/$(get_libdir)/libbz2.so.1 "${BC_LIB}/libbz2.so.1.0"

    local KDE6_PLUGINS="/usr/$(get_libdir)/qt6/plugins/kf6/kfileitemaction"
    if [ -d "${KDE6_PLUGINS}" ]; then
        insinto "${KDE6_PLUGINS}"
        newins "ext/bcompare_ext_kde6.amd64.so" "bcompare_ext_kde6.so"
    fi

    dodir "${BC_BIN}"
    cat <<-EOF >"${ED}${BC_BIN}/bcompare" || die
#!/bin/sh
export QT_QPA_PLATFORM=xcb
export LD_LIBRARY_PATH="${BC_LIB}:\${LD_LIBRARY_PATH}"
exec "${BC_LIB}/BCompare" "\$@"
EOF
    fperms +x "${BC_BIN}/bcompare"

    domenu bcompare.desktop
    doicon bcompare.png
    insinto /usr/share/mime/packages
    doins bcompare.xml

    dodoc -r help/*
}

pkg_postinst() {
	xdg_desktop_database_update
	xdg_mimeinfo_database_update
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_mimeinfo_database_update
}

