# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit font

DESCRIPTION="HarmonyOS Sans fonts"
HOMEPAGE="https://developer.huawei.com/consumer/en/doc/design-guides/font-0000001828772001"
SRC_URI="https://alliance-communityfile-drcn.dbankcdn.com/FileServer/getFile/cmtyManage/011/111/111/0000000000011111111.20260611171743.77886644144213121813005934094365:50001231000000:2800:0CCF575ADA0FCAD85EE25909C15C402A40FA94ABCCFEFC5BD37061A6B94239FF.zip -> ${P}.zip"
S="${WORKDIR}/HarmonyOS Sans"

LICENSE="HarmonyOS-Sans"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="mirror"

BDEPEND="app-arch/unzip"

# 2026.06.12+ zip flattens all ttf files in the archive root
FONT_S="${S}"
FONT_SUFFIX="ttf"

src_install() {
	font_src_install
}
