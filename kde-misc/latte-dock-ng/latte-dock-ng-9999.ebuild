# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake git-r3 xdg

DESCRIPTION="Wayland-first Latte Dock NG for Plasma 6.6+"
HOMEPAGE="https://github.com/ruizhi-lab/latte-dock-ng"
EGIT_REPO_URI="https://github.com/ruizhi-lab/latte-dock-ng.git"
EGIT_BRANCH="main"

LICENSE="GPL-2+ GPL-3+ LGPL-2+ || ( LGPL-2.1 LGPL-3 )"
SLOT="0"
KEYWORDS=""
PROPERTIES="live"

COMMON_DEPEND="
	>=dev-libs/plasma-wayland-protocols-1.6
	>=dev-libs/wayland-1.22
	>=dev-qt/qtbase-6.6:6[dbus,gui,widgets]
	>=dev-qt/qtdeclarative-6.6:6
	>=dev-qt/qtwayland-6.6:6
	>=kde-frameworks/karchive-6.0:6
	>=kde-frameworks/kconfig-6.0:6
	>=kde-frameworks/kcoreaddons-6.0:6
	>=kde-frameworks/kcrash-6.0:6
	>=kde-frameworks/kdbusaddons-6.0:6
	>=kde-frameworks/kdeclarative-6.0:6
	>=kde-frameworks/kglobalaccel-6.0:6
	>=kde-frameworks/kguiaddons-6.0:6
	>=kde-frameworks/ki18n-6.0:6
	>=kde-frameworks/kiconthemes-6.0:6
	>=kde-frameworks/kio-6.0:6
	>=kde-frameworks/knewstuff-6.0:6
	>=kde-frameworks/knotifications-6.0:6
	>=kde-frameworks/kpackage-6.0:6
	>=kde-frameworks/ksvg-6.0:6
	>=kde-frameworks/kwindowsystem-6.0:6
	>=kde-frameworks/kxmlgui-6.0:6
	>=kde-plasma/kpipewire-6.6:6
	>=kde-plasma/kwayland-6.6:6
	>=kde-plasma/libplasma-6.6:6
	>=kde-plasma/plasma-activities-6.6:6
	>=kde-plasma/plasma-activities-stats-6.6:6
	>=kde-plasma/plasma-workspace-6.6:6
"
RDEPEND="${COMMON_DEPEND}"
DEPEND="${COMMON_DEPEND}"
BDEPEND="
	>=kde-frameworks/extra-cmake-modules-6.0
	virtual/pkgconfig
"

src_configure() {
	local mycmakeargs=(
		-DBUILD_TESTING=OFF
	)

	cmake_src_configure
}

pkg_postinst() {
	xdg_pkg_postinst
}

pkg_postrm() {
	xdg_pkg_postrm
}
