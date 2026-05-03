# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

DESCRIPTION="Wayland-first Latte Dock NG for Plasma 6.6+"
HOMEPAGE="https://github.com/ruizhi-lab/latte-dock-ng"
SRC_URI="https://github.com/ruizhi-lab/latte-dock-ng/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

S="${WORKDIR}/${PN}-v${PV}"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
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
DEPEND="${RDEPEND}"
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
