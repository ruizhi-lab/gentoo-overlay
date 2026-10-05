# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit check-reqs edo git-r3 xdg

DESCRIPTION="Colloid icon theme for Linux desktops"
HOMEPAGE="https://github.com/vinceliuice/Colloid-icon-theme"
EGIT_REPO_URI="https://github.com/vinceliuice/Colloid-icon-theme.git"
EGIT_BRANCH="main"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS=""
IUSE="+minimal alternative bold kde"
PROPERTIES="live"
RESTRICT="binchecks strip test"

BDEPEND="app-shells/bash"

DOCS=( README.md )

colloid-icon-theme_check-reqs() {
	if ! use minimal; then
		CHECKREQS_DISK_USR=2600M
		check-reqs_${EBUILD_PHASE_FUNC}
	fi
}

pkg_setup() {
	colloid-icon-theme_check-reqs
}

pkg_pretend() {
	colloid-icon-theme_check-reqs
}

src_prepare() {
	default
	# The xdg eclass handles updating the icon cache.
	sed -i "/gtk-update-icon-cache/d" install.sh || die
}

src_install() {
	einstalldocs
	dodir /usr/share/icons

	local options=( -d "${ED}/usr/share/icons" )
	use kde && options+=( -p )
	use alternative && options+=( -a )
	use bold && options+=( -b )
	if ! use minimal; then
		options+=( -s all -t all )
	fi

	edob ./install.sh "${options[@]}"
	edob -m "Removing broken symlinks" find "${ED}" -xtype l -print -delete
}
