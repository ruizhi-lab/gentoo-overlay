# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake xdg

DESCRIPTION="Wayland-first Latte Dock NG for Plasma 6.6+"
HOMEPAGE="https://github.com/ruizhi-lab/latte-dock-ng"
SRC_URI="https://github.com/ruizhi-lab/latte-dock-ng/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"

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
	>=kde-frameworks/kitemmodels-6.0:6
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

	# Always install the fallback org.kde.plasma.private.taskmanager
	# unconditionally, so the files are owned by THIS package version.
	# Earlier revisions tried to skip when the live system already had a
	# qmldir there, but that path is broken on -rN -> -r(N+1) upgrades:
	# the previous revision's files are still on disk during src_install
	# (Portage hasn't unmerged the old slot yet), the conditional fires
	# 'system has it, skip', and the new package ends up not owning the
	# files. Portage then drops them when unmerging the old revision and
	# the dock comes up empty.
	#
	# Plasma 6.6+ doesn't ship this private module; if a future Plasma
	# release reintroduces it via plasma-workspace, the file collision
	# will be surfaced by Portage at install time and can be addressed
	# then.
	local taskmanager_qml_dir="/usr/$(get_libdir)/qt6/qml/org/kde/plasma/private/taskmanager"
	einfo "Installing Latte fallback org.kde.plasma.private.taskmanager QML module."
	insinto "${taskmanager_qml_dir}"
	doins "${S}"/compat/qml/org/kde/plasma/private/taskmanager/qmldir
	doins "${S}"/compat/qml/org/kde/plasma/private/taskmanager/Backend.qml
	doins "${S}"/compat/qml/org/kde/plasma/private/taskmanager/SmartLauncherItem.qml
	# Marker so future revisions / cmake-direct upgrades can recognize
	# our shim and overwrite it cleanly.
	: > "${ED}${taskmanager_qml_dir}/.latte-fallback-module"
}

pkg_postinst() {
	xdg_pkg_postinst
}

pkg_postrm() {
	xdg_pkg_postrm
}
