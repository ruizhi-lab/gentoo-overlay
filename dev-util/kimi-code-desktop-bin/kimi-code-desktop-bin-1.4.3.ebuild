# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit chromium-2 desktop optfeature pax-utils unpacker xdg

DESCRIPTION="Desktop GUI for the Kimi Code agent"
HOMEPAGE="https://www.kimi.com/code"

# The vendor publishes the same .deb on its CDN and in the GitHub release of
# MoonshotAI/kimi-code (tag kimi-code-desktop@${PV}); both carry identical
# contents, so the CDN URL is used because it does not need the tag suffix.
SRC_URI="https://code.kimi.com/kimi-code/desktop/binaries/${PV}/KimiCode-${PV}-linux-amd64.deb
	-> ${P}.deb"
S=${WORKDIR}

LICENSE="KimiCode"
SLOT="0"
KEYWORDS="-* ~amd64"
IUSE="wayland"
RESTRICT="bindist mirror strip"

RDEPEND="
	>=app-accessibility/at-spi2-core-2.46.0:2
	app-crypt/libsecret
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/libglvnd
	media-libs/mesa[gbm(+),vulkan]
	net-print/cups
	sys-apps/dbus
	sys-apps/util-linux
	sys-libs/glibc
	virtual/libudev
	x11-libs/cairo
	x11-libs/gdk-pixbuf:2
	x11-libs/gtk+:3
	x11-libs/libdrm
	x11-libs/libnotify
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libxcb
	x11-libs/libxkbcommon
	x11-libs/libXrandr
	x11-libs/libXScrnSaver
	x11-libs/libXtst
	x11-libs/pango
	x11-misc/xdg-utils
"

QA_PREBUILT="*"

src_prepare() {
	default

	local appdir="opt/Kimi Code"

	# The vendor ships a second copy of the AppStream file inside the
	# application directory; the one under usr/share is the installed one.
	if [[ -d ${appdir}/usr ]]; then
		rm -r "${appdir}/usr" || die
	fi

	# node-pty carries binaries and sources for every platform the vendor
	# targets; the Linux modules it needs are loaded from bin/ and
	# build/Release, so the cross-platform ones are dead weight here.
	local nodemod="${appdir}/resources/app.asar.unpacked/node_modules/node-pty"
	local dead=(
		"${nodemod}"/prebuilds
		"${nodemod}"/deps/winpty
	)
	local path
	for path in "${dead[@]}"; do
		if [[ -e ${path} ]]; then
			rm -r "${path}" || die
		fi
	done
}

src_configure() {
	default

	# The SUID sandbox is the fallback when unprivileged user namespaces are
	# unavailable, so the kernel needs the namespacing and seccomp options.
	chromium_suid_sandbox_check_kernel_config
}

src_install() {
	local appdir="/opt/${PN}"

	dodir /opt
	mv "opt/Kimi Code" "${ED}${appdir}" || die

	pax-mark m "${ED}${appdir}/kimi-code"
	pax-mark m "${ED}${appdir}/resources/app.asar.unpacked/node_modules/node-pty/build/Release/pty.node"

	# Chromium only uses the SUID helper where user namespaces fail, and it
	# insists on a setuid binary then. Portage merges as root, so ownership is
	# root regardless of the image.
	fperms 4711 "${appdir}/chrome-sandbox"

	# The executable keeps the upstream name because Electron derives the
	# window class, and with it StartupWMClass, from it.
	dosym -r "${appdir}/kimi-code" /usr/bin/kimi-code-desktop

	# The desktop file name is fixed: the application registers kimi-code://
	# deep links for its OAuth login with that name, and Electron looks up the
	# file through the desktopName field of the bundled package.json.
	newmenu "${FILESDIR}"/kimi-code.desktop kimi-code.desktop
	if use wayland; then
		local desktop="${ED}/usr/share/applications/kimi-code.desktop"
		local exec
		exec=$(sed -n 's/^Exec=\(.*\) %U$/\1/p' "${desktop}")
		[[ -n ${exec} ]] || die "unexpected Exec= line in kimi-code.desktop"
		# The hint follows the running session, so the same entry still starts
		# under X11 when a user has wayland in their global USE.
		sed -i "s|^Exec=.*|Exec=${exec} --ozone-platform-hint=auto --enable-wayland-ime %U|" \
			"${desktop}" || die
	fi

	doicon -s 512 usr/share/icons/hicolor/512x512/apps/kimi-code.png

	insinto /usr/share/metainfo
	doins usr/share/metainfo/com.kimi.code.desktop.metainfo.xml

	# The Electron and Chromium notices stay with the application files.
	dodir /usr/share/licenses/${PN}
	dosym -r "${appdir}/LICENSE.electron.txt" \
		"/usr/share/licenses/${PN}/LICENSE.electron.txt"
	dosym -r "${appdir}/LICENSES.chromium.html" \
		"/usr/share/licenses/${PN}/LICENSES.chromium.html"
}

pkg_postinst() {
	xdg_pkg_postinst

	elog "Kimi Code Desktop keeps its sessions and settings in ~/.kimi-code."
	elog "Set KIMI_CODE_HOME to use another directory."
	elog "Upgrades are merged by Portage; the application's own updater is not"
	elog "used for this installation."

	optfeature "system tray icon" dev-libs/libayatana-appindicator
}

pkg_postrm() {
	xdg_pkg_postrm
}
