# Copyright 2026
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake cuda git-r3 toolchain-funcs

DESCRIPTION="llama.cpp fork with Prism-ML Bonsai 1-bit model support"
HOMEPAGE="https://github.com/Mintplex-Labs/prism-ml-llama.cpp"
EGIT_REPO_URI="${HOMEPAGE}.git"
EGIT_BRANCH="prism"

LICENSE="MIT"
SLOT="0"
KEYWORDS=""
PROPERTIES="live"
IUSE="cuda curl openmp openssl vulkan"

RDEPEND="
	curl? ( net-misc/curl:= )
	cuda? ( dev-util/nvidia-cuda-toolkit:= )
	openmp? ( llvm-runtimes/openmp:= )
	openssl? ( dev-libs/openssl:= )
	vulkan? ( media-libs/vulkan-loader )
"
DEPEND="
	${RDEPEND}
	vulkan? (
		dev-util/spirv-headers
		dev-util/vulkan-headers
	)
"
BDEPEND="
	vulkan? ( media-libs/shaderc )
"

pkg_pretend() {
	use openmp && tc-check-openmp
}
pkg_setup() {
	use openmp && tc-check-openmp
}

src_prepare() {
	use cuda && cuda_src_prepare
	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DLLAMA_BUILD_TESTS=OFF
		-DLLAMA_BUILD_EXAMPLES=OFF
		-DLLAMA_BUILD_SERVER=ON
		-DLLAMA_BUILD_WEBUI=OFF
		-DLLAMA_TESTS_INSTALL=OFF
		-DLLAMA_CURL=$(usex curl)
		-DLLAMA_OPENSSL=$(usex openssl)
		-DGGML_NATIVE=OFF
		-DGGML_CUDA=$(usex cuda)
		-DGGML_OPENMP=$(usex openmp)
		-DGGML_RPC=ON
		-DGGML_VULKAN=$(usex vulkan)
		-DCMAKE_INSTALL_INCLUDEDIR="include/${PN}"
		-DCMAKE_INSTALL_LIBDIR="$(get_libdir)/${PN}"
		-DCMAKE_INSTALL_BINDIR="libexec/${PN}"
		-DCMAKE_INSTALL_RPATH="\$ORIGIN/../../$(get_libdir)/${PN};\$ORIGIN"
	)

	if use cuda; then
		local -x CUDAHOSTCXX="$(cuda_gccdir)"
		cuda_add_sandbox
		addpredict "/dev/char/"
	fi

	cmake_src_configure
}

src_install() {
	cmake_src_install

	local tool
	for tool in llama-cli llama-server; do
		dosym -r "/usr/libexec/${PN}/${tool}" "/usr/bin/prism-${tool}"
	done
}
