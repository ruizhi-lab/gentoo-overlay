# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop xdg

DESCRIPTION="A GUI client for Linux, support Xray and sing-box and others"
HOMEPAGE="https://github.com/2dust/v2rayN"
SRC_URI="https://github.com/2dust/v2rayN/releases/download/${PV}/v2rayN-linux-64.zip"

S="${WORKDIR}"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="-* ~amd64"
RESTRICT="strip mirror"

RDEPEND="
	media-libs/fontconfig
	media-libs/freetype
"

BDEPEND="app-arch/unzip"

QA_PREBUILT="*"

src_unpack() {
	default

	# The zip has a top-level directory (v2rayN-linux-64),
	# flatten it so S=WORKDIR works.
	local dir
	for dir in "${WORKDIR}"/v2rayN-linux-*; do
		if [[ -d "${dir}" ]]; then
			mv "${dir}"/* "${WORKDIR}"/ || die "failed to move extracted files"
			rmdir "${dir}" || die
			break
		fi
	done
}

src_install() {
	insinto /opt/v2rayn
	doins -r *

	fperms +x /opt/v2rayn/v2rayN
	fperms +x /opt/v2rayn/AmazTool
	fperms +x /opt/v2rayn/bin/xray/xray
	fperms +x /opt/v2rayn/bin/sing_box/sing-box
	fperms +x /opt/v2rayn/bin/mihomo/mihomo

	dosym -r /opt/v2rayn/v2rayN /usr/bin/v2rayn

	for size in 16 24 32 48 64 128 256; do
		newicon -s ${size} "${FILESDIR}"/icons/${size}x${size}/apps/v2rayn.png v2rayn.png
	done
	domenu "${FILESDIR}"/v2rayn.desktop
}

pkg_postinst() {
	xdg_pkg_postinst

	elog "v2rayN is installed in /opt/v2rayn"
	elog "Run with: v2rayn"
	elog "Core binaries (Xray, sing-box, mihomo) are bundled in /opt/v2rayn/bin/"
}

pkg_postrm() {
	xdg_pkg_postrm
}
