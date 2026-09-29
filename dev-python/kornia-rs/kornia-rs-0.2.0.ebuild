# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=no
DISTUTILS_EXT=1
# Upstream publishes CPython-specific wheels and has not released Python 3.15 wheels yet.
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1

MY_PN="kornia_rs"
MY_BASE="https://files.pythonhosted.org/packages"
AMD64_WHL_TAIL="manylinux_2_17_x86_64.manylinux2014_x86_64.whl"

DESCRIPTION="Python bindings for Rust computer vision operations (prebuilt wheels)"
HOMEPAGE="https://github.com/kornia/kornia-rs https://pypi.org/project/kornia-rs/"
SRC_URI="
	python_targets_python3_12? ( ${MY_BASE}/1b/01/05a31ef5ed358f9a086626718fb7bafba4a5f60e408ec1bb2309ba307779/${MY_PN}-${PV}-cp312-cp312-${AMD64_WHL_TAIL} )
	python_targets_python3_13? ( ${MY_BASE}/eb/4c/b7f9a36a6fe174069c9a6f2f6debea49e7c992dcbb8a768a217303ef1b49/${MY_PN}-${PV}-cp313-cp313-${AMD64_WHL_TAIL} )
	python_targets_python3_14? ( ${MY_BASE}/99/5b/eda16fb41f2321bbb227e53350bad5d1302100dbadb0386f6b1cdac9075b/${MY_PN}-${PV}-cp314-cp314-${AMD64_WHL_TAIL} )
"
S="${WORKDIR}"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"
# Upstream publishes only Rust-compiled extension wheels for supported interpreters.
RESTRICT="strip"

QA_PREBUILT="usr/lib/python3.*/site-packages/kornia_rs/*"
BDEPEND="dev-python/installer[${PYTHON_USEDEP}]"

src_unpack() {
	mkdir -p "${S}/wheel" || die
	local f
	for f in ${A}; do
		cp "${DISTDIR}/${f}" "${S}/wheel/" || die
	done
}

src_compile() { :; }

python_install() {
	local pyver=${EPYTHON#python}
	local cptag=cp${pyver//./}
	local whl="${MY_PN}-${PV}-${cptag}-${cptag}-${AMD64_WHL_TAIL}"
	[[ -f ${S}/wheel/${whl} ]] || die "expected wheel ${whl} not found"
	${EPYTHON} -m installer --destdir="${D}" "${S}/wheel/${whl}" || die
	python_optimize
}
