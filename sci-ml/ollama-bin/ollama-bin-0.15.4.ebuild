# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit systemd unpacker

DESCRIPTION="Local runner for LLMs (Binary version)"
HOMEPAGE="https://ollama.com/"

SRC_URI="https://github.com/ollama/ollama/releases/download/v${PV}/ollama-linux-amd64.tar.zst -> ${P}.tar.zst"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="systemd"

RDEPEND="
    acct-group/ollama
    acct-user/ollama
    dev-util/nvidia-cuda-toolkit
"
BDEPEND="app-arch/zstd"

S="${WORKDIR}"

src_install() {
    dobin bin/ollama
    
    insinto /usr/lib64
    doins -r lib/ollama

    if use systemd; then
        systemd_dounit "${FILESDIR}"/ollama.service
    fi
}
