EAPI=8

DESCRIPTION="Quarto scientific and technical publishing system"
HOMEPAGE="https://quarto.org"
SRC_URI="https://github.com/quarto-dev/quarto-cli/releases/download/v${PV}/quarto-${PV}-linux-amd64.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="strip mirror bindist"

S="${WORKDIR}/quarto-${PV}"

src_install() {
    insinto /opt/quarto
    doins -r .

    dosym /opt/quarto/bin/quarto /usr/bin/quarto
}
