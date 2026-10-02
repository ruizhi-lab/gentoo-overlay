# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
DISTUTILS_SINGLE_IMPL=1
PYTHON_COMPAT=( python3_{12..15} )

inherit distutils-r1

DESCRIPTION="Example workflow templates for ComfyUI"
HOMEPAGE="https://github.com/Comfy-Org/workflow_templates https://pypi.org/project/comfyui-workflow-templates/"
SRC_URI="https://files.pythonhosted.org/packages/c2/04/56b3cc657b278079d3cdbfb9e681a1ae141e5c4a4c9e70dabffd035f6ebc/comfyui_workflow_templates-0.11.70.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${PN//-/_}-${PV}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	~dev-python/comfyui-workflow-templates-core-0.3.361[${PYTHON_SINGLE_USEDEP}]
	~dev-python/comfyui-workflow-templates-json-0.1.96[${PYTHON_SINGLE_USEDEP}]
	~dev-python/comfyui-workflow-templates-media-api-0.3.84[${PYTHON_SINGLE_USEDEP}]
	~dev-python/comfyui-workflow-templates-media-video-0.3.101[${PYTHON_SINGLE_USEDEP}]
	~dev-python/comfyui-workflow-templates-media-image-0.3.160[${PYTHON_SINGLE_USEDEP}]
	~dev-python/comfyui-workflow-templates-media-other-0.3.229[${PYTHON_SINGLE_USEDEP}]
	~dev-python/comfyui-workflow-templates-media-assets-one-0.1.48[${PYTHON_SINGLE_USEDEP}]
	~dev-python/comfyui-workflow-templates-media-assets-two-0.1.6[${PYTHON_SINGLE_USEDEP}]
"

BDEPEND="$(python_gen_cond_dep '
	>=dev-python/setuptools-61[${PYTHON_USEDEP}]
')"
