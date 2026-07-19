# Copyright 2023-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

ALTERNATIVES=(
	v2fly:virtual/v2ray-geoip
	"loyalsoldier:dev-libs/v2ray-rules-dat-bin[geoip]"
)

inherit app-alternatives

DESCRIPTION="symlink for v2ray-geoip"
HOMEPAGE="https://wiki.gentoo.org/wiki/Project:Base/Alternatives"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

src_install() {
	dosym -r "/usr/share/geoip/$(get_alternative).dat" /usr/share/v2ray/geoip.dat
}
