# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake cuda toolchain-funcs

LLAMA_COMMIT="b81c99b479d4c24e5eeca10de99032ebd343ef8f"

DESCRIPTION="CUDA llama.cpp runtime with tiered KV memory for long contexts"
HOMEPAGE="https://github.com/kvmem/kvmem-llama.cpp"
SRC_URI="
	https://github.com/kvmem/kvmem-llama.cpp/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/ggml-org/llama.cpp/archive/${LLAMA_COMMIT}.tar.gz -> llama.cpp-${LLAMA_COMMIT}.tar.gz
"
S="${WORKDIR}/kvmem-llama.cpp-${PV}"

LICENSE="Apache-2.0 MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="cpu_flags_x86_avx cpu_flags_x86_avx2 cpu_flags_x86_bmi2
	cpu_flags_x86_f16c cpu_flags_x86_fma3 cpu_flags_x86_sse4_2 +openmp test"
RESTRICT="!test? ( test )"

# Upstream requires nvcc >= 13.2.86 (CUDA 13.2 Update 2) for IQ3 correctness.
RDEPEND="
	>=dev-util/nvidia-cuda-toolkit-13.2.2:=
	openmp? ( llvm-runtimes/openmp:= )
"
DEPEND="${RDEPEND}"
RDEPEND+=" x11-drivers/nvidia-drivers"
BDEPEND=">=dev-util/nvidia-cuda-toolkit-13.2.2"

PATCHES=( "${FILESDIR}/${P}-cxxflags.patch" )

pkg_pretend() {
	use openmp && tc-check-openmp
}

pkg_setup() {
	use openmp && tc-check-openmp
}

src_prepare() {
	rmdir llama.cpp || die
	mv "${WORKDIR}/llama.cpp-${LLAMA_COMMIT}" llama.cpp || die
	pushd llama.cpp >/dev/null || die
	eapply "${S}/patches/llama-kvmem-current.patch"
	popd >/dev/null || die

	cuda_src_prepare
	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DBUILD_SHARED_LIBS=OFF
		-DKVMEM_BUILD_LLAMA=ON
		-DKVMEM_ENABLE_NVME=ON
		-DGGML_CUDA=ON
		-DGGML_NATIVE=OFF
		-DGGML_AVX=$(usex cpu_flags_x86_avx)
		-DGGML_AVX2=$(usex cpu_flags_x86_avx2)
		-DGGML_BMI2=$(usex cpu_flags_x86_bmi2)
		-DGGML_F16C=$(usex cpu_flags_x86_f16c)
		-DGGML_FMA=$(usex cpu_flags_x86_fma3)
		-DGGML_SSE42=$(usex cpu_flags_x86_sse4_2)
		-DGGML_CCACHE=OFF
		-DGGML_OPENMP=$(usex openmp)
		-DGGML_VULKAN=OFF
		-DLLAMA_OPENSSL=OFF
		# The server needs the mtmd target defined by llama.cpp/tools.
		-DLLAMA_BUILD_TOOLS=ON
		-DLLAMA_BUILD_UI=OFF
	)
	if [[ -n ${CMAKE_CUDA_ARCHITECTURES} ]]; then
		mycmakeargs+=( -DCMAKE_CUDA_ARCHITECTURES="${CMAKE_CUDA_ARCHITECTURES}" )
	fi
	local -x CUDAHOSTCXX="$(cuda_gccdir)"
	cuda_add_sandbox
	addpredict /dev/char/
	cmake_src_configure
}

src_compile() {
	# Build only the runtime tools; upstream also defines model-dependent tests.
	cmake_src_compile llama-kvmem-cli llama-kvmem-server
}

src_test() {
	# Model-free host-memory tests; GPU/MTP tests need separately supplied GGUFs.
	local targets=(
		kvmem_store_test pinned_kv_tier_test
		nvme_kv_tier_test kvmem_runtime_test raw_kv_store_test
	)
	cmake_src_compile "${targets[@]}"
	local pattern
	pattern=$(IFS='|'; echo "${targets[*]}")
	ctest --test-dir "${BUILD_DIR}" --output-on-failure -R "^(${pattern})$" || die
}

src_install() {
	# Keep patched llama/ggml private and avoid installing their SDK or tools.
	dobin "${BUILD_DIR}/bin/llama-kvmem-cli" "${BUILD_DIR}/bin/llama-kvmem-server"
	dodoc README.md VERSION
	newdoc llama.cpp/LICENSE LICENSE.llama.cpp
	dodoc "${FILESDIR}/README.gentoo"
}
