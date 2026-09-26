# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..14} )
DISTUTILS_SINGLE_IMPL=1
DISTUTILS_USE_PEP517=setuptools
DISTUTILS_EXT=1

inherit distutils-r1

DESCRIPTION="Fast kernel library for ComfyUI with multiple compute backends"
HOMEPAGE="https://github.com/Comfy-Org/comfy-kitchen"
FLASH_ATTENTION_URI="https://github.com/Dao-AILab/flash-attention/archive"
FLASH_ATTENTION_COMMIT="979702c87a8713a8e0a5e9fee122b90d2ef13be5"
CUTLASS_URI="https://github.com/NVIDIA/cutlass/archive"
CUTLASS_COMMIT="d4b4b494c3c51bf6507e7ab09fbafd1e9fa94f39"
SRC_URI="
	https://github.com/Comfy-Org/comfy-kitchen/archive/refs/tags/v${PV}.tar.gz -> ${P}.gh.tar.gz
	${FLASH_ATTENTION_URI}/${FLASH_ATTENTION_COMMIT}.tar.gz -> flash-attention-979702c.gh.tar.gz
	${CUTLASS_URI}/${CUTLASS_COMMIT}.tar.gz -> cutlass-d4b4b49.gh.tar.gz
"
S="${WORKDIR}/comfy-kitchen-${PV}"

LICENSE="Apache-2.0 BSD"
SLOT="0"
KEYWORDS="~amd64"
IUSE="cuda rocm"
REQUIRED_USE="?? ( cuda rocm )"

BDEPEND="
	>=dev-build/cmake-3.26
	dev-build/ninja
	$(python_gen_cond_dep '
		>=dev-python/nanobind-2.0.0[${PYTHON_USEDEP}]
		>=dev-python/setuptools-61[${PYTHON_USEDEP}]
	')
	cuda? ( >=dev-util/nvidia-cuda-toolkit-13.0 )
	rocm? ( dev-util/hip )
"
RDEPEND="
	!cuda? ( !rocm? ( >=sci-ml/pytorch-2.7.0[${PYTHON_SINGLE_USEDEP}] ) )
	cuda? ( >=sci-ml/pytorch-2.13[cuda,${PYTHON_SINGLE_USEDEP}] )
	rocm? ( >=sci-ml/pytorch-2.13[rocm,${PYTHON_SINGLE_USEDEP}] )
"
DEPEND="${RDEPEND}"

RESTRICT="test"

src_prepare() {
	default
	rmdir third_party/flash-attention third_party/cutlass || die
	mv "${WORKDIR}/flash-attention-979702c87a8713a8e0a5e9fee122b90d2ef13be5" third_party/flash-attention || die
	mv "${WORKDIR}/cutlass-d4b4b494c3c51bf6507e7ab09fbafd1e9fa94f39" third_party/cutlass || die
}

python_configure_all() {
	DISTUTILS_ARGS=()
	if use rocm; then
		DISTUTILS_ARGS+=( --no-cuda --hip )
	elif ! use cuda; then
		DISTUTILS_ARGS+=( --no-cuda --no-hip )
	fi
}

python_compile() {
	if use cuda; then
		export COMFY_KITCHEN_BUILD_NO_HIP=1
	elif use rocm; then
		export COMFY_KITCHEN_BUILD_HIP=1
	fi
	distutils-r1_python_compile
}
