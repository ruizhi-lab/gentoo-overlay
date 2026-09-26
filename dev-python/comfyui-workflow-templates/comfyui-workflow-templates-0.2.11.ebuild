# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
DISTUTILS_SINGLE_IMPL=1
PYTHON_COMPAT=( python3_{12..15} )

inherit distutils-r1

DESCRIPTION="Example workflow templates for ComfyUI"
HOMEPAGE="https://github.com/Comfy-Org/workflow_templates https://pypi.org/project/comfyui-workflow-templates/"
SRC_URI="https://files.pythonhosted.org/packages/4d/d9/caa0f8a1b94e33c7a6a51a47f22f50b25bc1c506c4551df4468b3f9595fe/comfyui_workflow_templates-0.2.11.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${PN//-/_}-${PV}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

BDEPEND="$(python_gen_cond_dep '
	>=dev-python/setuptools-61[${PYTHON_USEDEP}]
')"
