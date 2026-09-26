# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..14} )
inherit python-single-r1

DESCRIPTION="Modular diffusion model GUI, API and backend with a graph/nodes interface"
HOMEPAGE="https://www.comfy.org/ https://github.com/Comfy-Org/ComfyUI"
SRC_URI="https://github.com/Comfy-Org/ComfyUI/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/ComfyUI-${PV}"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE="cuda rocm optional"
REQUIRED_USE="${PYTHON_REQUIRED_USE} ?? ( cuda rocm )"

RDEPEND="
	${PYTHON_DEPS}
	~dev-python/comfyui-embedded-docs-0.5.12[${PYTHON_SINGLE_USEDEP}]
	~dev-python/comfyui-frontend-package-1.52.7[${PYTHON_SINGLE_USEDEP}]
	~dev-python/comfyui-workflow-templates-0.11.66[${PYTHON_SINGLE_USEDEP}]
	~dev-python/comfy-aimdo-0.5.5[${PYTHON_SINGLE_USEDEP}]
	~dev-python/comfy-kitchen-0.2.35[cuda?,rocm?,${PYTHON_SINGLE_USEDEP}]
	>=sci-ml/tokenizers-0.13.3[${PYTHON_SINGLE_USEDEP}]
	sci-ml/torchsde[${PYTHON_SINGLE_USEDEP}]
	>=sci-ml/transformers-4.50.3[${PYTHON_SINGLE_USEDEP}]
	$(python_gen_cond_dep '
		dev-python/alembic[${PYTHON_USEDEP}]
		>=dev-python/aiohttp-3.11.8[${PYTHON_USEDEP}]
		>=dev-python/av-17.0.0[${PYTHON_USEDEP}]
		sci-ml/einops[${PYTHON_USEDEP}]
		>=dev-python/numpy-1.25.0[${PYTHON_USEDEP}]
		dev-python/psutil[${PYTHON_USEDEP}]
		dev-python/pillow[${PYTHON_USEDEP}]
		dev-python/pyyaml[${PYTHON_USEDEP}]
		>=sci-ml/safetensors-0.4.2[${PYTHON_USEDEP}]
		dev-python/scipy[${PYTHON_USEDEP}]
		sci-ml/sentencepiece[${PYTHON_USEDEP}]
		>=dev-python/sqlalchemy-2.0.0[${PYTHON_USEDEP}]
		dev-python/tqdm[${PYTHON_USEDEP}]
		>=dev-python/yarl-1.18.0[${PYTHON_USEDEP}]
		dev-python/filelock[${PYTHON_USEDEP}]
		dev-python/requests[${PYTHON_USEDEP}]
		>=dev-python/simpleeval-1.0.0[${PYTHON_USEDEP}]
		dev-python/blake3[${PYTHON_USEDEP}]
	')
	!cuda? ( !rocm? (
		>=sci-ml/pytorch-2.12.0[${PYTHON_SINGLE_USEDEP}]
		sci-ml/torchaudio[${PYTHON_SINGLE_USEDEP}]
		sci-ml/torchvision[${PYTHON_SINGLE_USEDEP}]
	) )
	$(python_gen_cond_dep '
		>=dev-python/pydantic-2.0.0[${PYTHON_USEDEP}]
		<dev-python/pydantic-3.0.0[${PYTHON_USEDEP}]
	')
	cuda? (
		>=sci-ml/pytorch-2.13[cuda,${PYTHON_SINGLE_USEDEP}]
		sci-ml/torchaudio[cuda,${PYTHON_SINGLE_USEDEP}]
		sci-ml/torchvision[cuda,${PYTHON_SINGLE_USEDEP}]
	)
	rocm? (
		>=sci-ml/pytorch-2.13[rocm,${PYTHON_SINGLE_USEDEP}]
		sci-ml/torchaudio[${PYTHON_SINGLE_USEDEP}]
		sci-ml/torchvision[rocm,${PYTHON_SINGLE_USEDEP}]
	)
	optional? (
		sci-ml/kornia[${PYTHON_SINGLE_USEDEP}]
		sci-ml/spandrel[${PYTHON_SINGLE_USEDEP}]
		$(python_gen_cond_dep '
			>=dev-python/pydantic-settings-2.0.0[${PYTHON_USEDEP}]
			<dev-python/pydantic-settings-3.0.0[${PYTHON_USEDEP}]
			>=dev-python/pyopengl-3.1.8[${PYTHON_USEDEP}]
		')
	)
"

src_install() {
	insinto "/usr/lib/${PN}"
	doins -r .

	cat > "${T}/${PN}" <<-EOF_LAUNCHER
	#!/bin/sh
	data_dir=\${XDG_DATA_HOME:-\${HOME}/.local/share}/comfyui
	mkdir -p "\${data_dir}" || exit 1
	exec ${EPYTHON} /usr/lib/${PN}/main.py --base-directory "\${data_dir}" "\$@"
	EOF_LAUNCHER
	dobin "${T}/${PN}"
}
