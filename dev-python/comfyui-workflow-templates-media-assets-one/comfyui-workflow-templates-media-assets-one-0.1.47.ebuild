# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
DISTUTILS_SINGLE_IMPL=1
PYTHON_COMPAT=( python3_{12..15} )
# Upstream PN ends in a numeric component, which is invalid as a Gentoo PN.
PYPI_PN="comfyui-workflow-templates-media-assets-01"

inherit distutils-r1 pypi

DESCRIPTION="Media asset workflows for ComfyUI (set 01)"
HOMEPAGE="https://github.com/Comfy-Org/workflow_templates https://pypi.org/project/comfyui-workflow-templates-media-assets-01/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

BDEPEND="$(python_gen_cond_dep '
	>=dev-python/setuptools-61[${PYTHON_USEDEP}]
')"
