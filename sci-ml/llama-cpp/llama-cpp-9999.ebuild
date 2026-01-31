EAPI=8

inherit git-r3 cmake toolchain-funcs

DESCRIPTION="Inference of LLaMA models in pure C/C++"
HOMEPAGE="https://github.com/ggml-org/llama.cpp"

EGIT_REPO_URI="https://github.com/ggml-org/llama.cpp.git"

LICENSE="MIT"
SLOT="0"
KEYWORDS=""

IUSE="cuda vulkan native"

DEPEND="
    dev-build/cmake
    dev-vcs/git
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

