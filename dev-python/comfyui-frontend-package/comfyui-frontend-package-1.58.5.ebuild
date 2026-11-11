# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
DISTUTILS_SINGLE_IMPL=1
PYTHON_COMPAT=( python3_{12..15} )

inherit distutils-r1

DESCRIPTION="Bundled web frontend assets for ComfyUI"
HOMEPAGE="https://github.com/Comfy-Org/ComfyUI_frontend https://pypi.org/project/comfyui-frontend-package/"
SRC_URI="https://files.pythonhosted.org/packages/a7/95/35052db164d0a43d7d1c21d64a5896e4c94470e3d4e47742764ad28dd49d/comfyui_frontend_package-1.58.5.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${PN//-/_}-${PV}"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

BDEPEND="$(python_gen_cond_dep '
	>=dev-python/setuptools-61[${PYTHON_USEDEP}]
')"

src_configure() {
	export COMFYUI_FRONTEND_VERSION="${PV}"
	distutils-r1_src_configure
}
