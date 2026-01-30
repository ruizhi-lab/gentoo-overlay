EAPI=8

DESCRIPTION="Quarto scientific and technical publishing system (binary distribution)"
HOMEPAGE="https://quarto.org/"
SRC_URI="https://github.com/quarto-dev/quarto-cli/releases/download/v${PV}/quarto-${PV}-linux-amd64.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="strip mirror"

QA_PREBUILT="*"

DEPEND=""
RDEPEND="${DEPEND}"

S="${WORKDIR}/quarto-${PV}"

src_install() {
    # Install everything under /opt/quarto
    insinto /opt/quarto
    doins -r .

    # Ensure main executable has +x
    exeinto /opt/quarto/bin
    doexe bin/quarto

    # Symlink into PATH
    dosym /opt/quarto/bin/quarto /usr/bin/quarto
}

