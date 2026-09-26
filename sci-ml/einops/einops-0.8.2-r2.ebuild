# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..15} )
DISTUTILS_USE_PEP517=hatchling
EPYTEST_PLUGINS=()

inherit distutils-r1 pypi

DESCRIPTION="Flexible and powerful tensor operations for readable and reliable code"
HOMEPAGE="https://github.com/arogozhnikov/einops"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

distutils_enable_tests pytest
