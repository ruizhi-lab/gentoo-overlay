EAPI=8

inherit cmake toolchain-funcs

DESCRIPTION="Inference of LLaMA models in pure C/C++"
HOMEPAGE="https://github.com/ggml-org/llama.cpp"

COMMIT="22cae832188a1f08d18bd0a707a4ba5cd03c7349"
SRC_URI="https://github.com/ggml-org/llama.cpp/archive/${COMMIT}.tar.gz -> ${P}.tar.gz"

S="${WORKDIR}/llama.cpp-${COMMIT}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

IUSE="cuda vulkan native"

DEPEND="
    net-misc/curl
    cuda? ( dev-util/nvidia-cuda-toolkit )
    vulkan? ( media-libs/vulkan-loader )
"

src_configure() {
    export CC=/usr/bin/gcc-14
    export CXX=/usr/bin/g++-14
    export CUDAHOSTCXX="$(tc-getCXX)"

    local cuda_arch="native"

    local mycmakeargs=(
        -DBUILD_SHARED_LIBS=ON
        -DGGML_NATIVE=$(usex native ON OFF)
        -DGGML_CUDA=$(usex cuda ON OFF)
        -DGGML_VULKAN=$(usex vulkan ON OFF)
        -DGGML_CUDA_F16C=ON
        -DGGML_CUDA_DMMV=ON
        -DCMAKE_CUDA_ARCHITECTURES=${cuda_arch}
        -DGGML_AVX512=$(usex native ON OFF)
    )

    cmake_src_configure
}

