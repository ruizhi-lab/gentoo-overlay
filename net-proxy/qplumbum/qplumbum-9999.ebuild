# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v3

EAPI=8

inherit cmake git-r3 xdg

DESCRIPTION="Qt 6 Linux GUI client for Xray and V2Ray"
HOMEPAGE="https://github.com/ruizhi-lab/Qplumbum"
EGIT_REPO_URI="https://github.com/ruizhi-lab/Qplumbum.git"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS=""
PROPERTIES="live"

DEPEND="
	dev-libs/openssl
	dev-libs/protobuf
	dev-qt/qtbase:6[gui,network,widgets]
	dev-qt/qtdeclarative:6
	dev-qt/qtsvg:6
	dev-qt/qttools:6
	net-libs/grpc
	net-misc/curl
"
RDEPEND="${DEPEND}"
BDEPEND="dev-build/cmake"

src_configure() {
	local mycmakeargs=(
		-DPLUMBUM_AUTO_DEPLOY=OFF
		-DPLUMBUM_EMBED_TRANSLATIONS=ON
		-DPLUMBUM_HAS_SINGLEAPPLICATION=ON
		-DPLUMBUM_UI_TYPE=QML
		-DPLUMBUM_USE_V5_CORE=ON
	)

	cmake_src_configure
}

src_install() {
	cmake_src_install
}

pkg_postinst() {
	xdg_pkg_postinst

	einfo "Plumbum is installed as a frontend for Xray/V2Ray."
	einfo "Configure the core executable and geo data paths in Plumbum's settings."
}

pkg_postrm() {
	xdg_pkg_postrm
}
