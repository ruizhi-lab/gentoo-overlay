# xrdp-0.10.4.1.ebuild
EAPI=8
inherit git-r3

DESCRIPTION="Remote Desktop Protocol (RDP) server"
HOMEPAGE="https://github.com/neutrinolabs/xrdp"
EGIT_REPO_URI="https://github.com/neutrinolabs/xrdp.git"
SRC_URI=""

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="sys-libs/pam"
DEPEND="${RDEPEND}"

src_prepare() {
    default
}

src_configure() {
    ./bootstrap
    ./configure --prefix=/usr --sysconfdir=/etc
}

src_compile() {
    emake
}

src_install() {
    emake DESTDIR="${D}" install
}

pkg_postinst() {
    elog "xrdp installed. Please enable and start the service if needed."
}

