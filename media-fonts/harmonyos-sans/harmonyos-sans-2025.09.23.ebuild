# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit font

DESCRIPTION="HarmonyOS Sans fonts"
HOMEPAGE="https://developer.huawei.com/consumer/en/doc/design-guides/font-0000001828772001"
SRC_URI="https://github.com/huawei-fonts/HarmonyOS-Sans/raw/33ab3b81b92c01f5e340c89960872bee174d8704/HarmonyOS%20Sans.zip -> ${P}.zip"
S="${WORKDIR}/HarmonyOS Sans"

LICENSE="HarmonyOS-Sans"
SLOT="0"
KEYWORDS="~amd64 ~x86"
RESTRICT="mirror"

BDEPEND="app-arch/unzip"

FONT_SUFFIX="ttf"

src_install() {
	insinto "${FONTDIR}"
	find . -type f -name "*.ttf" -print0 | while IFS= read -r -d '' font_file; do
		doins "${font_file}"
	done

	dodoc HarmonyOS_Sans/LICENSE.txt
}
