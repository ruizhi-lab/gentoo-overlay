# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
DISTUTILS_SINGLE_IMPL=1
PYTHON_COMPAT=( python3_{12..15} )

inherit distutils-r1

DESCRIPTION="Example workflow templates for ComfyUI"
HOMEPAGE="https://github.com/Comfy-Org/workflow_templates https://pypi.org/project/comfyui-workflow-templates/"
SRC_URI="https://files.pythonhosted.org/packages/13/bf/73f39b88013187749d72f1a73487aea1a9aaec24a8fc2d487c3d9503b631/comfyui_workflow_templates-0.11.76.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${PN//-/_}-${PV}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	~dev-python/comfyui-workflow-templates-core-0.3.367[${PYTHON_SINGLE_USEDEP}]
	~dev-python/comfyui-workflow-templates-json-0.1.102[${PYTHON_SINGLE_USEDEP}]
	~dev-python/comfyui-workflow-templates-media-api-0.3.84[${PYTHON_SINGLE_USEDEP}]
	~dev-python/comfyui-workflow-templates-media-video-0.3.101[${PYTHON_SINGLE_USEDEP}]
	~dev-python/comfyui-workflow-templates-media-image-0.3.160[${PYTHON_SINGLE_USEDEP}]
	~dev-python/comfyui-workflow-templates-media-other-0.3.229[${PYTHON_SINGLE_USEDEP}]
	~dev-python/comfyui-workflow-templates-media-assets-one-0.1.48[${PYTHON_SINGLE_USEDEP}]
	~dev-python/comfyui-workflow-templates-media-assets-two-0.1.9[${PYTHON_SINGLE_USEDEP}]
"

BDEPEND="$(python_gen_cond_dep '
	>=dev-python/setuptools-61[${PYTHON_USEDEP}]
')"
