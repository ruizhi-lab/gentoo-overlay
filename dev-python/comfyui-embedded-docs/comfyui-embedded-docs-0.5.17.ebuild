# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
DISTUTILS_SINGLE_IMPL=1
PYTHON_COMPAT=( python3_{12..15} )

inherit distutils-r1

DESCRIPTION="Embedded per-node documentation assets for ComfyUI"
HOMEPAGE="https://github.com/Comfy-Org/embedded-docs https://pypi.org/project/comfyui-embedded-docs/"
SRC_URI="https://files.pythonhosted.org/packages/ae/15/247d23cfb47dc53049a9e34ed546279c4f04fb862fe191b45f11b2713ffd/comfyui_embedded_docs-0.5.17.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${PN//-/_}-${PV}"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

BDEPEND="$(python_gen_cond_dep '
	>=dev-python/setuptools-61[${PYTHON_USEDEP}]
')"
