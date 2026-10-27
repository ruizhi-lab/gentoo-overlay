# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
DISTUTILS_SINGLE_IMPL=1
PYTHON_COMPAT=( python3_{12..15} )

inherit distutils-r1

DESCRIPTION="Bundled web frontend assets for ComfyUI"
HOMEPAGE="https://github.com/Comfy-Org/ComfyUI_frontend https://pypi.org/project/comfyui-frontend-package/"
SRC_URI="https://files.pythonhosted.org/packages/45/2e/63d0f722365112a36b558405a811c9fe9089ba814e8beb0bf8bd2120f8c8/comfyui_frontend_package-1.57.4.tar.gz -> ${P}.tar.gz"
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
