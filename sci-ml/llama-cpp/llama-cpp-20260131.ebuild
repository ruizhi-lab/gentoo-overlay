EAPI=8

inherit cmake toolchain-funcs

DESCRIPTION="Inference of LLaMA models in pure C/C++"
HOMEPAGE="https://github.com/ggml-org/llama.cpp"

COMMIT="89f10baad5a1809055d71110dff60e55561b9c62"
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

    local mycmakeargs=(
        -DBUILD_SHARED_LIBS=ON
        -DGGML_NATIVE=$(usex native ON OFF)
        -DGGML_CUDA=$(usex cuda ON OFF)
        -DGGML_VULKAN=$(usex vulkan ON OFF)
    )

    cmake_src_configure
}

