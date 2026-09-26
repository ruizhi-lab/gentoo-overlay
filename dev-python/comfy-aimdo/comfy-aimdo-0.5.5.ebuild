# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..14} )
DISTUTILS_SINGLE_IMPL=1
DISTUTILS_USE_PEP517=setuptools
PATCHES=( "${FILESDIR}/${P}-respect-ldflags.patch" )

inherit distutils-r1

DESCRIPTION="AI model dynamic offloader for ComfyUI"
HOMEPAGE="https://github.com/Comfy-Org/comfy-aimdo https://pypi.org/project/comfy-aimdo/"
SRC_URI="
	https://github.com/Comfy-Org/comfy-aimdo/archive/refs/tags/v${PV}.tar.gz -> ${P}.gh.tar.gz
	https://github.com/kubo/funchook/archive/refs/tags/v1.1.3.tar.gz -> funchook-1.1.3.gh.tar.gz
	https://github.com/gdabah/distorm/archive/ab59d6e193948cfa5d1482fb6c7e64870e9e93b9.tar.gz -> distorm-ab59d6e.gh.tar.gz
"
S="${WORKDIR}/comfy-aimdo-${PV}"

LICENSE="GPL-3 GPL-2+ BSD"
SLOT="0"
KEYWORDS="~amd64"

BDEPEND="
	dev-build/cmake
	$(python_gen_cond_dep '
		>=dev-python/setuptools-61[${PYTHON_USEDEP}]
		dev-python/setuptools-scm[${PYTHON_USEDEP}]
		dev-python/wheel[${PYTHON_USEDEP}]
	')
"
RDEPEND=">=sci-ml/pytorch-2.8.0[${PYTHON_SINGLE_USEDEP}]"
DEPEND="${RDEPEND}"

RESTRICT="test"

src_prepare() {
	default
	mkdir -p build || die
	mv "${WORKDIR}/funchook-1.1.3" build/funchook-1.1.3 || die
	rmdir build/funchook-1.1.3/distorm || die
	mv "${WORKDIR}/distorm-ab59d6e193948cfa5d1482fb6c7e64870e9e93b9" build/funchook-1.1.3/distorm || die
}

src_compile() {
	export SETUPTOOLS_SCM_PRETEND_VERSION="${PV}"
	export AIMDO_EXTRA_CFLAGS="${CFLAGS}"
	bash ./scripts/build-linux-aimdo.sh || die "failed to build native AIMDO backends"
	distutils-r1_src_compile
}
