# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd

DESCRIPTION="Xray, Penetrates Everything. Prebuilt upstream binary"
HOMEPAGE="https://xtls.github.io/ https://github.com/XTLS/Xray-core"
SRC_URI="https://github.com/XTLS/Xray-core/releases/download/v${PV}/Xray-linux-64.zip -> ${P}-linux-64.zip"

S="${WORKDIR}"

LICENSE="MPL-2.0"
SLOT="0"
KEYWORDS="-* ~amd64"

RDEPEND="
	!net-proxy/Xray
	app-alternatives/v2ray-geoip
	app-alternatives/v2ray-geosite
"
BDEPEND="app-arch/unzip"
RESTRICT="strip mirror"
QA_PREBUILT="/usr/bin/xray"

src_install() {
	dobin xray

	newinitd "${FILESDIR}/xray.initd" xray
	systemd_dounit "${FILESDIR}/xray.service"
	systemd_newunit "${FILESDIR}/xray_at.service" xray@.service

	# xray looks up geoip.dat/geosite.dat via XRAY_LOCATION_ASSET; point it at
	# /usr/share/v2ray (managed by app-alternatives) instead of installing the
	# bundled dat files or /usr/share/xray symlinks (the latter would collide
	# with net-proxy/v2rayA).
	newenvd - 99xray <<-EOF
	XRAY_LOCATION_ASSET=/usr/share/v2ray
	EOF

	keepdir /etc/xray
}
