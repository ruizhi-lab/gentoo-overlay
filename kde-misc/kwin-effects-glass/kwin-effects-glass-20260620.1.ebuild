# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit ecm

DESCRIPTION="Liquid Glass-like blur and refraction effect for KDE Plasma 6"
HOMEPAGE="https://github.com/4v3ngR/kwin-effects-glass"
MY_TAG="${PV/./-}"
SRC_URI="https://github.com/4v3ngR/kwin-effects-glass/archive/refs/tags/${MY_TAG}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/kwin-effects-glass-${MY_TAG}"

PATCHES=( "${FILESDIR}/kwin-effects-glass-20260620-kwin-66.patch" )

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+wayland X"
REQUIRED_USE="|| ( wayland X )"

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
