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

# Sets COMFY_CUDA_ARCHS for setup.py, which passes it to CMake. A value that is
# already in the environment, for example from /etc/portage/env, is kept.
# Otherwise the architectures are read from the GPUs of the build machine with
# nvidia-smi. No card is written into this ebuild, because a CUDA binary holds
# code only for the architectures it was built for.
cuda_select_architectures() {
	if [[ -n ${COMFY_CUDA_ARCHS} ]]; then
		return
	fi

	local caps cap archs=() major minor
	caps=$(nvidia-smi --query-gpu=compute_cap --format=csv,noheader 2>/dev/null) \
		|| die "COMFY_CUDA_ARCHS is not set and nvidia-smi did not answer; set COMFY_CUDA_ARCHS in /etc/portage/env/${PN}"

	for cap in $(printf '%s\n' ${caps} | sort -u); do
		[[ ${cap} =~ ^[0-9]+\.[0-9]+$ ]] \
			|| die "nvidia-smi reported an unexpected compute capability: ${cap}"
		major=${cap%%.*}
		minor=${cap#*.}
		# Hopper uses the a-specific code, Blackwell and later the family code,
		# as upstream's default list does; other GPUs use plain real code.
		case ${major} in
			9) archs+=( "90a-real" ) ;;
			1[0-9]) archs+=( "${major}${minor}f" ) ;;
			*) archs+=( "${major}${minor}-real" ) ;;
		esac
	done
	[[ ${#archs[@]} -gt 0 ]] || die "nvidia-smi reported no compute capability"

	local IFS=';'
	export COMFY_CUDA_ARCHS="${archs[*]}"
}

pkg_setup() {
	# Defining pkg_setup replaces python-single-r1_pkg_setup, which sets EPYTHON.
	python-single-r1_pkg_setup

	if ! use cuda; then
		return 0
	fi

	cuda_select_architectures
	einfo "CUDA architectures: ${COMFY_CUDA_ARCHS}"
	ewarn "The CUDA build runs only on these architectures. Rebuild comfy-kitchen after"
	ewarn "changing the GPUs, or set COMFY_CUDA_ARCHS in /etc/portage/env/${PN} to build"
	ewarn "for other cards, for example COMFY_CUDA_ARCHS=\"120f\" for RTX 50 series."
	ewarn "Without COMFY_CUDA_ARCHS, the architectures come from the GPUs in this machine."
	ewarn "nvcc accepts host GCC only up to the GCC_MAX_VER of the CUDA toolkit: 14 for"
	ewarn "CUDA 12.9.2 and 16 for CUDA 13.4.1. If the current GCC is newer, build with an"
	ewarn "older GCC."
	return 0
}

python_compile() {
	if use cuda; then
		export COMFY_KITCHEN_BUILD_NO_HIP=1
		# setup.py looks for nvcc in CUDA_HOME, then in PATH, then in
		# /usr/local/cuda. The toolkit this ebuild depends on is installed
		# under /opt/cuda, which is in PATH only when the system adds it.
		export CUDA_HOME="${CUDA_HOME:-${EPREFIX}/opt/cuda}"
		cuda_select_architectures
	elif use rocm; then
		export COMFY_KITCHEN_BUILD_HIP=1
	fi
	distutils-r1_python_compile
}

pkg_postinst() {
	if use cuda; then
		elog "The CUDA binary of comfy-kitchen runs only on the GPU architectures it was"
		elog "built for. Rebuild it after changing the GPUs or the CUDA toolkit."
	fi
}
