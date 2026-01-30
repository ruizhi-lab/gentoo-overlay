# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="HarmonyOS Sans Fonts. 华为鸿蒙字体"
HOMEPAGE="https://developer.huawei.com/consumer/cn/design/resource/"
SRC_URI="https://alliance-communityfile-drcn.dbankcdn.com/FileServer/getFile/cmtyManage/011/111/111/0000000000011111111.20250923104318.11664078982054632530113858317517:50001231000000:2800:C0DB7AC2067D28B96607BC0D598A48EAF74CA1B7D936B819A36F67CB6E071F30.zip -> ${P}.zip"

LICENSE="LicenseRef-custom"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

SRC_URI_SHA256=('0bb556d79c65f4778e33d9b5835e5133bce4ad9ee46f823a5a3dcda888610e78')

pkgname="ttf-harmonyos-sans"
_pkgname='HarmonyOS Sans 字体'

# 指定源码目录
S="${WORKDIR}/${_pkgname}"

src_prepare() {
    default
}

src_compile() {
    :  # no compilation needed
}

src_install() {
    export LC_CTYPE="zh_CN.UTF-8"

    find "${S}" -type f -name "*.ttf" \
        -exec install -Dm644 -t "${ED}/usr/share/fonts/${PN}" {} +

    install -Dm644 "${S}/LICENSE.txt" -t "${ED}/usr/share/licenses/${PN}"

    exe 0 fc-cache -fv
}

