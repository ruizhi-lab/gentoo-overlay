# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake cuda toolchain-funcs

# llama.cpp commit pinned by upstream in backends/versions.json, with the ordered
# patch series that file also records (backends/patches/llamacpp-*.patch).
LLAMA_COMMIT="620d2225cc436ab0b001e3200e590e3b286ef9ab"
# The series has to be applied in this order: each patch declares the ones it
# requires, and upstream's prepare-backends.py rejects a different sequence.
LLAMA_PATCHES=(
	llamacpp-kvmem
	llamacpp-pq2
	llamacpp-ptq1
	llamacpp-ptq1-performance
	llamacpp-checkpoint-policy
)

DESCRIPTION="CUDA llama.cpp runtime with tiered KV memory for long contexts"
HOMEPAGE="https://github.com/kvmem/kvmem"
SRC_URI="
	https://github.com/kvmem/kvmem/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/ggml-org/llama.cpp/archive/${LLAMA_COMMIT}.tar.gz -> llama.cpp-${LLAMA_COMMIT}.tar.gz
"
S="${WORKDIR}/kvmem-${PV}"

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

PATCHES=(
	"${FILESDIR}/${P}-cxxflags.patch"
	"${FILESDIR}/${P}-nvml-deprecated.patch"
)

pkg_pretend() {
	use openmp && tc-check-openmp
}

pkg_setup() {
	use openmp && tc-check-openmp
}

src_prepare() {
	# The llama.cpp backend lives in backends/llamacpp, an empty submodule
	# directory in the release tarball. Upstream's scripts/prepare-backends.py
	# needs the git metadata of that submodule to verify its patch series, which
	# a tarball build does not have, so the pinned tree is unpacked here and the
	# same series, in the same order, is applied with eapply.
	rmdir backends/llamacpp || die
	mv "${WORKDIR}/llama.cpp-${LLAMA_COMMIT}" backends/llamacpp || die

	pushd backends/llamacpp >/dev/null || die
	local patch
	for patch in "${LLAMA_PATCHES[@]}"; do
		eapply "${S}/backends/patches/${patch}.patch"
	done
	popd >/dev/null || die

	cuda_src_prepare
	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DBUILD_SHARED_LIBS=OFF
		-DKVMEM_BUILD_LLAMA=ON
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
		# The server links mtmd, which llama.cpp defines under tools/.
		-DLLAMA_BUILD_TOOLS=ON
	)
	# llama.cpp's own server target stays off: upstream forces it off in its
	# directory, and the two tools installed below are the only entry points
	# this package offers.
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
	# The NVMe store has been retired upstream (docs/legacy-ssd-retirement), so
	# its test target is gone; the shared RAM/SSD tiers are covered by
	# host_kv_storage_test and tiered_kv_storage_test.
	local targets=(
		kvmem_store_test pinned_kv_tier_test host_kv_storage_test
		tiered_kv_storage_test kvmem_runtime_test raw_kv_store_test
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
	newdoc backends/llamacpp/LICENSE LICENSE.llama.cpp
	dodoc "${FILESDIR}/README.gentoo"
}
