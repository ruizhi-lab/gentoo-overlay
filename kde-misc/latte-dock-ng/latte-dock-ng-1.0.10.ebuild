# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake xdg

DESCRIPTION="Wayland-first Latte Dock NG for Plasma 6.6+"
HOMEPAGE="https://github.com/ruizhi-lab/latte-dock-ng"
SRC_URI="https://github.com/ruizhi-lab/latte-dock-ng/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2+ GPL-3+ LGPL-2+ || ( LGPL-2.1 LGPL-3 )"
SLOT="0"
KEYWORDS="~amd64"

COMMON_DEPEND="
	>=dev-libs/plasma-wayland-protocols-1.6
	>=dev-libs/wayland-1.22
	>=dev-qt/qtbase-6.6:6[dbus,gui,widgets]
	>=dev-qt/qtdeclarative-6.6:6
	>=dev-qt/qtwayland-6.6:6
	>=kde-frameworks/karchive-6.0:6
	>=kde-frameworks/kconfig-6.0:6
	>=kde-frameworks/kcoreaddons-6.0:6
	>=kde-frameworks/kcrash-6.0:6
	>=kde-frameworks/kdbusaddons-6.0:6
	>=kde-frameworks/kdeclarative-6.0:6
	>=kde-frameworks/kglobalaccel-6.0:6
	>=kde-frameworks/kguiaddons-6.0:6
	>=kde-frameworks/ki18n-6.0:6
	>=kde-frameworks/kiconthemes-6.0:6
	>=kde-frameworks/kio-6.0:6
	>=kde-frameworks/knewstuff-6.0:6
	>=kde-frameworks/knotifications-6.0:6
	>=kde-frameworks/kpackage-6.0:6
	>=kde-frameworks/ksvg-6.0:6
	>=kde-frameworks/kwindowsystem-6.0:6
	>=kde-frameworks/kxmlgui-6.0:6
	>=kde-plasma/kpipewire-6.6:6
	>=kde-plasma/kwayland-6.6:6
	>=kde-plasma/libplasma-6.6:6
	>=kde-plasma/plasma-activities-6.6:6
	>=kde-plasma/plasma-activities-stats-6.6:6
	>=kde-plasma/plasma-workspace-6.6:6
"
RDEPEND="${COMMON_DEPEND}"
DEPEND="${COMMON_DEPEND}"
BDEPEND="
	>=kde-frameworks/extra-cmake-modules-6.0
	virtual/pkgconfig
"

src_configure() {
	local mycmakeargs=(
		-DBUILD_TESTING=OFF
	)

	cmake_src_configure
}

src_install() {
	cmake_src_install

	# 1.0.10's compat/qml/CMakeLists.txt installs the fallback
	# org.kde.plasma.private.taskmanager *only* when the host system doesn't
	# already provide a qmldir there. That's correct for cmake-direct users,
	# but on Gentoo it would skip the install when an earlier ebuild revision
	# (e.g. =1.0.9-r1) put the fallback there via doins — those files are
	# owned by the older slot and Portage drops them on upgrade, leaving the
	# system without the module. Re-install unconditionally so 1.0.10 owns
	# the files in its own vdb entry.
	local taskmanager_qml_dir="/usr/$(get_libdir)/qt6/qml/org/kde/plasma/private/taskmanager"

	if [[ -e "${ESYSROOT}${taskmanager_qml_dir}/qmldir" \
			&& ! -e "${ESYSROOT}${taskmanager_qml_dir}/.latte-fallback-module" ]]; then
		einfo "System org.kde.plasma.private.taskmanager appears to be upstream; not overwriting."
	else
		einfo "Installing Latte fallback org.kde.plasma.private.taskmanager QML module."
		insinto "${taskmanager_qml_dir}"
		doins "${S}"/compat/qml/org/kde/plasma/private/taskmanager/qmldir
		doins "${S}"/compat/qml/org/kde/plasma/private/taskmanager/Backend.qml
		doins "${S}"/compat/qml/org/kde/plasma/private/taskmanager/SmartLauncherItem.qml
		# Marker for cmake-direct upgrades and future ebuild revisions to
		# recognize that this is our shim and may be safely overwritten.
		: > "${ED}${taskmanager_qml_dir}/.latte-fallback-module"
	fi
}

pkg_postinst() {
	xdg_pkg_postinst
}

pkg_postrm() {
	xdg_pkg_postrm
}
