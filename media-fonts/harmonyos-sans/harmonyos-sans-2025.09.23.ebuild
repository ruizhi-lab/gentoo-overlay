EAPI=8

inherit font

DESCRIPTION="HarmonyOS Sans fonts (华为鸿蒙字体)"
HOMEPAGE="https://developer.huawei.com/consumer/cn/design/resource/"
SRC_URI="https://alliance-communityfile-drcn.dbankcdn.com/...zip -> ${P}.zip"

LICENSE="LicenseRef-custom"
SLOT="0"
KEYWORDS="~amd64 ~x86"

BDEPEND="app-arch/unzip"

S="${WORKDIR}/HarmonyOS Sans 字体"

FONT_SUFFIX="ttf"

RESTRICT="mirror"

src_install() {
    insinto "${FONTDIR}"

    find . -type f -name "*.ttf" -print0 | while IFS= read -r -d '' f; do
        doins "$f"
    done

    dodoc LICENSE.txt
}
