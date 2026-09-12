# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit ecm git-r3

DESCRIPTION="Liquid Glass-like blur and refraction effect for KDE Plasma 6"
HOMEPAGE="https://github.com/4v3ngR/kwin-effects-glass"
EGIT_REPO_URI="https://github.com/4v3ngR/kwin-effects-glass.git"
EGIT_BRANCH="main"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS=""
IUSE="+wayland X"
REQUIRED_USE="|| ( wayland X )"
PROPERTIES="live"

COMMON_DEPEND="
	>=dev-qt/qtbase-6.6:6[dbus,gui,network,opengl,widgets,xml]
	>=kde-frameworks/kcmutils-6.0:6
	>=kde-frameworks/kguiaddons-6.0:6
	>=kde-frameworks/ki18n-6.0:6
	>=kde-plasma/kdecoration-6.0:6
	>=kde-plasma/kwin-6.6:6
	wayland? ( >=dev-libs/wayland-1.22 )
	X? (
		x11-libs/libX11
		x11-libs/libxcb
	)
"
RDEPEND="${COMMON_DEPEND}"
DEPEND="${COMMON_DEPEND}"
BDEPEND="
	sys-devel/gettext
	virtual/pkgconfig
"

src_configure() {
	local mycmakeargs=(
		-DBUILD_TESTING=OFF
		-DGLASS_WAYLAND=$(usex wayland)
		-DGLASS_X11=$(usex X)
	)

	cmake_src_configure
}
