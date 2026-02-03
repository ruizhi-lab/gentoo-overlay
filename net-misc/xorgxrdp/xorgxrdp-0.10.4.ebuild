# xorgxrdp-0.10.4.ebuild
EAPI=8
inherit git-r3

DESCRIPTION="Xorg driver modules for XRDP"
HOMEPAGE="https://github.com/neutrinolabs/xorgxrdp"
EGIT_REPO_URI="https://github.com/neutrinolabs/xorgxrdp.git"
SRC_URI=""

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="x11-base/xorg-server dev-lang/nasm net-misc/xrdp"
DEPEND="${RDEPEND}"

src_prepare() {
    default
    EPATCH="${EPATCH:-patch}"
}

src_configure() {
    ./bootstrap
    ./configure --prefix=/usr --sysconfdir=/etc \
        XRDP_CFLAGS="-I/usr/include -I/usr/include/xrdp" \
        XRDP_LIBS="-L/usr/lib"
}

src_compile() {
    emake
}

src_install() {
    emake DESTDIR="${D}" install
}

pkg_postinst() {
    needrelink_xorg_modules
}

