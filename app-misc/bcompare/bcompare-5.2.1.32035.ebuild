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
IUSE="kde"
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

	# 1. Regression to original file set (Minimalist approach)
	# We ONLY install the absolute essentials to avoid library conflicts
	exeinto "${BC_LIB}"
	doexe BCompare
	
	insinto "${BC_LIB}"
	doins BCompare.mad libcloudstorage.so.22.0
	
	# Use system's p7zip for 7z support (Just like your original version)
	dosym /usr/$(get_libdir)/p7zip/7z.so "${BC_LIB}/lib7z.so"
	# Ensure bzip2 compatibility
	dosym /usr/$(get_libdir)/libbz2.so.1 "${BC_LIB}/libbz2.so.1.0"

	# 2. KDE 6 Context Menu Plugin (Optional)
	if use kde; then
		local KDE6_PLUGINS="/usr/$(get_libdir)/qt6/plugins/kf6/kfileitemaction"
		# Use newexe to ensure 0755 execution permissions
		exeinto "${KDE6_PLUGINS}"
		newexe "ext/bcompare_ext_kde6.amd64.so" "bcompare_ext_kde6.so"
	fi

	# 3. Optimized Wrapper Script (Silence errors + Force Stability)
	dodir "${BC_BIN}"
	cat <<-EOF >"${ED}${BC_BIN}/bcompare" || die
#!/bin/sh
# Force X11 backend for stability
export QT_QPA_PLATFORM=xcb

# Suppress Qt noise (QComboBox warnings, etc.)
export QT_LOGGING_RULES="qt.core.qobject.connect.warning=false;*.debug=false"

# Use basic dialogs to prevent crashes on high-end desktop environments
export QT_NO_NATIVE_FILE_DIALOGS=1

# Prioritize our minimal lib dir
export LD_LIBRARY_PATH="${BC_LIB}:\${LD_LIBRARY_PATH}"

# Execute and redirect stderr to silence QThreadStorage cleanup messages
exec "${BC_LIB}/BCompare" "\$@" 2>/dev/null
EOF
	fperms +x "${BC_BIN}/bcompare"

	# 4. Integration Files
	domenu bcompare.desktop
	doicon bcompare.png
	insinto /usr/share/mime/packages
	doins bcompare.xml
	
	insinto /usr/share/pixmaps
	doins bcomparefull32.png bcomparehalf32.png

	dodoc -r help/*

	# 5. revdep-rebuild mask
	insinto /etc/revdep-rebuild
	echo "SEARCH_DIRS_MASK=\"${BC_LIB}\"" > "${T}/20${PN}"
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

