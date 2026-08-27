# Copyright 2021-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module systemd

DESCRIPTION="A platform for building proxies to bypass network restrictions"
HOMEPAGE="https://www.v2fly.org/ https://github.com/v2fly/v2ray-core"

if [[ "${PV}" == 9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/v2fly/v2ray-core.git"
else
	SRC_URI="
		https://github.com/v2fly/v2ray-core/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
		https://github.com/gentoo-zh-drafts/v2ray-core/releases/download/v${PV}/v2ray-core-${PV}-vendor.tar.xz
"
	KEYWORDS="~amd64"
	S="${WORKDIR}/${PN}-core-${PV}"
fi

# main
LICENSE="MIT"
# deps
LICENSE+=" Apache-2.0 BSD ISC"
SLOT="0"

RESTRICT="test"

DEPEND="!net-proxy/v2ray-bin"
RDEPEND="
	!net-proxy/v2ray-bin
	app-alternatives/v2ray-geoip
	app-alternatives/v2ray-geosite
"
BDEPEND=">=dev-lang/go-1.25.5:="

src_unpack() {
	if [[ "${PV}" == 9999* ]]; then
		git-r3_src_unpack
		pushd "${S}" || die
		ego mod tidy
		popd || die
		go-module_live_vendor
	else
		default
	fi
}

src_prepare() {
	sed -i 's|/usr/local/bin|/usr/bin|;s|/usr/local/etc|/etc|' release/config/systemd/system/*.service || die
	sed -i '/^User=/s/nobody/v2ray/;/^User=/aDynamicUser=true' release/config/systemd/system/*.service || die
	default
}

src_compile() {
	local CUSTOM_VER="${PV}"
	[[ ${PV} == 9999* ]] && CUSTOM_VER="$(git rev-parse --short HEAD)"

	CGO_ENABLED=0 ego build -o v2ray -trimpath \
		-ldflags "-X github.com/v2fly/v2ray-core/v5/core.build=${CUSTOM_VER}" ./main
}

src_install() {
	dobin v2ray

	insinto /etc/v2ray
	newins release/config/config.json config.json.example

	newinitd "${FILESDIR}/v2ray.initd-r1" v2ray
	systemd_dounit release/config/systemd/system/v2ray{,@}.service
}
