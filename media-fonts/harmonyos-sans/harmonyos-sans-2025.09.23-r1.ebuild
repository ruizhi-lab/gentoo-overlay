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
KEYWORDS="~amd64"
RESTRICT="mirror"

BDEPEND="app-arch/unzip"

FONT_S=(
	"${S}"/HarmonyOS_Sans
	"${S}"/HarmonyOS_Sans_Condensed
	"${S}"/HarmonyOS_Sans_Condensed_Italic
	"${S}"/HarmonyOS_Sans_Italic
	"${S}"/HarmonyOS_Sans_Naskh_Arabic
	"${S}"/HarmonyOS_Sans_Naskh_Arabic_UI
	"${S}"/HarmonyOS_Sans_SC
	"${S}"/HarmonyOS_Sans_TC
)
FONT_SUFFIX="ttf"

src_install() {
	font_src_install
	dodoc HarmonyOS_Sans/LICENSE.txt
}
