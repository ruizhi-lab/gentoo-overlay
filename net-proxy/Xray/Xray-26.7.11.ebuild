# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module systemd

DESCRIPTION="Xray, Penetrates Everything. Also the best v2ray-core, with XTLS support"
HOMEPAGE="https://xtls.github.io/ https://github.com/XTLS/Xray-core"
# maintainer generated vendor pack, see gentoo-zh-drafts/Xray-core
SRC_URI="
	https://github.com/XTLS/Xray-core/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/gentoo-zh-drafts/Xray-core/releases/download/v${PV}/Xray-core-${PV}-vendor.tar.xz
"

S="${WORKDIR}/${PN}-core-${PV}"

LICENSE="MPL-2.0"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	!net-proxy/Xray-bin
	app-alternatives/v2ray-geoip
	app-alternatives/v2ray-geosite
"
BDEPEND=">=dev-lang/go-1.26.0"

src_compile() {
	ego build -o xray -gcflags="all=-l=4" \
		-ldflags "-X github.com/XTLS/Xray-core/core.build=${PV}" ./main
}

src_install() {
	dobin xray

	newinitd "${FILESDIR}/xray.initd" xray
	systemd_dounit "${FILESDIR}/xray.service"
	systemd_newunit "${FILESDIR}/xray_at.service" xray@.service

	# xray looks up geoip.dat/geosite.dat via XRAY_LOCATION_ASSET; point it at
	# /usr/share/v2ray (managed by app-alternatives) instead of installing
	# /usr/share/xray symlinks, which would collide with net-proxy/v2rayA.
	newenvd - 99xray <<-EOF
	XRAY_LOCATION_ASSET=/usr/share/v2ray
	EOF

	keepdir /etc/xray
}
