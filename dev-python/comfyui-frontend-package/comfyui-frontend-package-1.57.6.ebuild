# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
DISTUTILS_SINGLE_IMPL=1
PYTHON_COMPAT=( python3_{12..15} )

inherit distutils-r1

DESCRIPTION="Bundled web frontend assets for ComfyUI"
HOMEPAGE="https://github.com/Comfy-Org/ComfyUI_frontend https://pypi.org/project/comfyui-frontend-package/"
SRC_URI="https://files.pythonhosted.org/packages/f7/90/83975b3d034788183e9f21a47d78fabf450544b9a27e10c0af402b907807/comfyui_frontend_package-1.57.6.tar.gz -> ${P}.tar.gz"
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
