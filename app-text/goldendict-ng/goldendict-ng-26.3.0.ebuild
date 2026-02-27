# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake plocale

DESCRIPTION="The Next Generation GoldenDict. Feature-rich dictionary lookup program"
HOMEPAGE="https://xiaoyifang.github.io/goldendict-ng"
SRC_URI="https://codeload.github.com/xiaoyifang/goldendict-ng/tar.gz/refs/tags/v${PV}-Release.fce2b872 -> ${P}.tar.gz"

S="${WORKDIR}/${PN}-${PV}-Release.fce2b872"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE="ffmpeg zim epwing"

RDEPEND="
	app-arch/bzip2
	app-i18n/opencc
	app-text/hunspell
	dev-libs/lzo
	dev-libs/xapian
	app-arch/xz-utils
	dev-libs/kdsingleapplication
	dev-libs/eb
	dev-libs/libfmt
	dev-cpp/tomlplusplus
	dev-qt/qtbase:6[X,gui,network,sql,widgets,xml]
	dev-qt/qtmultimedia:6
	dev-qt/qtspeech:6
	dev-qt/qtsvg:6
	dev-qt/qttools:6[assistant,linguist]
	dev-qt/qtwebengine:6
	media-libs/libvorbis
	media-libs/tiff:0
	virtual/zlib
	ffmpeg? (
		media-video/ffmpeg:0=
	)
	zim? (
		app-arch/libzim
	)
	epwing? (
		dev-libs/eb
	)
"

DEPEND="${RDEPEND}"
BDEPEND="
	virtual/pkgconfig
"

src_configure() {
	local mycmakeargs=(
		-DCMAKE_BUILD_TYPE=Release
		-DWITH_FFMPEG_PLAYER=$(usex ffmpeg ON OFF)
		-DWITH_ZIM=$(usex zim ON OFF)
		-DWITH_EPWING_SUPPORT=$(usex epwing ON OFF)
		-DUSE_SYSTEM_FMT=ON
		-DUSE_SYSTEM_TOML=ON
	)

	cmake_src_configure
}

