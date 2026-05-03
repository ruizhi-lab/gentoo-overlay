# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Quarto scientific and technical publishing system (binary distribution)"
HOMEPAGE="https://quarto.org/"
SRC_URI="https://github.com/quarto-dev/quarto-cli/releases/download/v${PV}/quarto-${PV}-linux-amd64.tar.gz"
S="${WORKDIR}/quarto-${PV}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="mirror strip"

QA_PREBUILT="opt/quarto/*"

src_install() {
	insinto /opt/quarto
	doins -r .
	fperms -R +x /opt/quarto/bin
	dosym ../../opt/quarto/bin/quarto /usr/bin/quarto
}
