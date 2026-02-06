# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd toolchain-funcs

DESCRIPTION="Get up and running with large language models, locally."
HOMEPAGE="https://github.com/ollama/ollama"

SRC_URI="
    https://github.com/ollama/ollama/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
    ollama-${PV}-vendor.tar.gz
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="cuda vulkan"

COMMON_DEPEND="
    acct-group/ollama
    acct-user/ollama
"

DEPEND="
    ${COMMON_DEPEND}
    >=dev-lang/go-1.22
    dev-build/cmake
    cuda? ( dev-util/nvidia-cuda-toolkit )
    vulkan? ( media-libs/vulkan-loader )
"

RDEPEND="${COMMON_DEPEND}"

S="${WORKDIR}/${P}"

src_unpack() {
    default

    if [[ -d "${WORKDIR}/vendor" ]]; then
        mv "${WORKDIR}/vendor" "${S}/" || die
    fi
}

src_compile() {
    export CC=$(tc-getCC)
    export CXX=$(tc-getCXX)
    export CUDAHOSTCXX=$(tc-getCXX)

    export CGO_ENABLED=1
    export GOPROXY=off
    export GONOSUMDB="*"

    go build -v -o ollama .
}

src_install() {
    dobin ollama

    systemd_dounit "${FILESDIR}/ollama.service"

    keepdir /var/lib/ollama
    fowners ollama:ollama /var/lib/ollama
}

