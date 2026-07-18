# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop toolchain-funcs xdg-utils

DESCRIPTION="Compare, merge files and folders using simple, powerful commands"
HOMEPAGE="https://www.scootersoftware.com"
SRC_URI="
	https://www.scootersoftware.com/${P}.x86_64.tar.gz
	https://downloads.sourceforge.net/sevenzip/7-Zip/26.01/7z2601-src.tar.xz
"

LICENSE="Bcompare"
SLOT="0"
KEYWORDS="~amd64"
IUSE="caja kde nautilus nemo thunar"
QA_PREBUILT="
	usr/lib/beyondcompare/*
	usr/lib/beyondcompare/ext/*
	usr/lib*/caja/extensions-2.0/bcompare-ext-caja.so
	usr/lib*/nautilus/extensions-4/bcompare-ext-nautilus.so
	usr/lib*/nemo/extensions-3.0/bcompare-ext-nemo.so
	usr/lib*/qt6/plugins/kf6/kfileitemaction/bcompare_ext_kde6.so
	usr/lib*/thunarx-3/bcompare-ext-thunarx.so
"

RESTRICT="bindist mirror strip"
RDEPEND="
	app-arch/7zip
	app-arch/bzip2
	app-arch/unrar
	dev-libs/libqt6pas
	dev-qt/qtbase:6[gui,widgets]
	sys-apps/dbus
	virtual/zlib
	x11-libs/libX11
	x11-libs/libxkbcommon
	caja? ( mate-base/caja )
	kde? ( kde-frameworks/kio:6 )
	nautilus? ( gnome-base/nautilus )
	nemo? ( gnome-extra/nemo )
	thunar? ( xfce-base/thunar )
"
BDEPEND="
	app-arch/xz-utils[extra-filters(+)]
"

src_unpack() {
	unpack ${P}.x86_64.tar.gz
	unpack 7z2601-src.tar.xz
}

src_compile() {
	# Remove -Werror to avoid build failures from harmless warnings
	sed -i 's/-Werror //g' "${WORKDIR}/CPP/7zip/7zip_gcc.mak" || die

	pushd "${WORKDIR}/CPP/7zip/Bundles/Format7zF" > /dev/null || die
	emake -f makefile.gcc \
		CC="$(tc-getCC)" \
		CXX="$(tc-getCXX)"
	popd > /dev/null || die
}

src_install() {
	local BC_LIB="/usr/lib/beyondcompare"
	local BC_BIN="/usr/bin"

	# Install lib7z.so built from 7-zip source
	exeinto "${BC_LIB}"
	newexe "${WORKDIR}/CPP/7zip/Bundles/Format7zF/_o/7z.so" lib7z.so

	# BCompare binary
	doexe BCompare

	insinto "${BC_LIB}"
	doins BCompare.mad libcloudstorage.so.22.0

	local ext_files=()
	use caja && ext_files+=( ext/bcompare-ext-caja.amd64.so )
	use kde && ext_files+=( ext/bcompare_ext_kde6.amd64.so )
	use nautilus && ext_files+=(
		ext/bcompare-ext-nautilus.amd64.so
		ext/bcompare-ext-nautilus.amd64.so.ext4
	)
	use nemo && ext_files+=( ext/bcompare-ext-nemo.amd64.so )
	use thunar && ext_files+=( ext/bcompare-ext-thunarx-3.amd64.so )

	if [[ ${#ext_files[@]} -gt 0 ]]; then
		# Skip legacy Qt/i386 plugins that cannot resolve on current Gentoo.
		insinto "${BC_LIB}/ext"
		doins "${ext_files[@]}"
	fi

	# bzip2 compatibility
	dosym ../../$(get_libdir)/libbz2.so.1 "${BC_LIB}/libbz2.so.1.0"

	if use caja; then
		local CAJA_PLUGINS="/usr/$(get_libdir)/caja/extensions-2.0"
		exeinto "${CAJA_PLUGINS}"
		newexe "ext/bcompare-ext-caja.amd64.so" "bcompare-ext-caja.so"
	fi

	# KDE 6 Context Menu Plugin (Optional)
	if use kde; then
		local KDE6_PLUGINS="/usr/$(get_libdir)/qt6/plugins/kf6/kfileitemaction"
		exeinto "${KDE6_PLUGINS}"
		newexe "ext/bcompare_ext_kde6.amd64.so" "bcompare_ext_kde6.so"
	fi

	if use nautilus; then
		local NAUTILUS_PLUGINS="/usr/$(get_libdir)/nautilus/extensions-4"
		exeinto "${NAUTILUS_PLUGINS}"
		newexe "ext/bcompare-ext-nautilus.amd64.so.ext4" "bcompare-ext-nautilus.so"
	fi

	if use nemo; then
		local NEMO_PLUGINS="/usr/$(get_libdir)/nemo/extensions-3.0"
		exeinto "${NEMO_PLUGINS}"
		newexe "ext/bcompare-ext-nemo.amd64.so" "bcompare-ext-nemo.so"
	fi

	if use thunar; then
		local THUNAR_PLUGINS="/usr/$(get_libdir)/thunarx-3"
		exeinto "${THUNAR_PLUGINS}"
		newexe "ext/bcompare-ext-thunarx-3.amd64.so" "bcompare-ext-thunarx.so"
	fi

	# Wrapper Script
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

	# Integration Files
	domenu bcompare.desktop
	doicon bcompare.png
	insinto /usr/share/mime/packages
	doins bcompare.xml

	insinto /usr/share/pixmaps
	doins bcomparefull32.png bcomparehalf32.png

	dodoc -r help/*

	# revdep-rebuild mask
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
