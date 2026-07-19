# Copyright 2019-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit unpacker xdg

QQ_DOWNLOAD_URL_PREFIX="https://qqdl.gtimg.cn/qqfile/QQNT/9.9.32/patch/c390e792"

DESCRIPTION="The new version of the official linux-qq"
HOMEPAGE="https://im.qq.com/index/#/linux"
SRC_URI="${QQ_DOWNLOAD_URL_PREFIX}/linuxqq_${PV/_*/}-51102_amd64.deb -> ${P}_amd64.deb"

S="${WORKDIR}"

LICENSE="Tencent"
SLOT="0"
KEYWORDS="-* ~amd64"

IUSE="bwrap system-fdk-aac system-libssh2 system-openh264 system-zlib gnome"

RESTRICT="strip mirror"
QA_PREBUILT="*"

RDEPEND="
	app-accessibility/at-spi2-core:2
	app-crypt/libsecret
	bwrap? (
		sys-apps/bubblewrap
		x11-misc/flatpak-xdg-utils
		x11-misc/snapd-xdg-open
	)
	dev-libs/nss
	gnome? ( dev-libs/gjs )
	media-libs/alsa-lib
	media-libs/libpulse
	media-libs/mesa
	media-libs/openslide
	net-print/cups
	sys-apps/keyutils
	system-fdk-aac? ( media-libs/fdk-aac )
	system-libssh2? ( net-libs/libssh2 )
	system-openh264? ( media-libs/openh264 )
	system-zlib? ( virtual/zlib )
	virtual/krb5
	x11-libs/gtk+:3
	x11-libs/libnotify
	x11-libs/libXdamage
	x11-libs/libXcomposite
	x11-libs/libXft
	x11-libs/libXScrnSaver
	x11-libs/libXtst
	x11-libs/libxkbcommon
	x11-misc/xdg-utils
"

src_unpack() {
	:
}

src_install() {
	dodir /opt
	cd "${D}" || die

	unpacker "${DISTDIR}/${P}_${ARCH}.deb"

	rm -r "${D}/usr/share/doc" || die

	if use system-fdk-aac; then
		rm -v "${D}/opt/QQ/resources/app/avsdk/libfdk-aac.so" || die
	fi
	if use system-libssh2; then
		rm -v "${D}/opt/QQ/resources/app/libssh2.so.1" "${D}/opt/QQ/resources/app/avsdk/bugly/libssh2.so.1" || die
	fi
	if use system-openh264; then
		rm -v "${D}/opt/QQ/resources/app/avsdk/libopenh264.so" || die
	fi
	if use system-zlib; then
		rm -v "${D}/opt/QQ/libz.so.1" || die
	fi

	if use bwrap; then
		newbin "${FILESDIR}/bwrap.sh" qq

		insinto /opt/QQ/workarounds
		doins "${FILESDIR}"/{config.json,xdg-open.sh,vercmp.sh}
		fperms +x /opt/QQ/workarounds/{xdg-open.sh,vercmp.sh}

		local base_ver=${PV/_p/-}
		local cur_ver=${base_ver}
		local build_ver=${cur_ver#*-}

		sed -i "s|__BASE_VER__|${base_ver}|g;s|__CURRENT_VER__|${cur_ver}|g;s|__BUILD_VER__|${build_ver}|g" \
			"${D}/opt/QQ/workarounds/config.json" \
			"${D}/usr/bin/qq" || die
	else
		newbin "${FILESDIR}/qq.sh" qq
	fi

	sed -i 's:^Exec=.*$:Exec=/usr/bin/qq %U:g;s:^Icon=.*$:Icon=qq:g' "${D}/usr/share/applications/qq.desktop" || die
}

pkg_postinst() {
	xdg_pkg_postinst
	if use bwrap; then
		elog "Enabled Bubblewrap support."
		elog "If you want to download files to the system download folder in QQ,"
		elog "set the download folder to the system download folder in the QQ settings."
	fi
}
