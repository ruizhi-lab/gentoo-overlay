# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )
inherit autotools pam python-single-r1 tmpfiles

DESCRIPTION="Server Administration Web Interface"
HOMEPAGE="https://cockpit-project.org/"
SRC_URI="https://github.com/cockpit-project/${PN}/releases/download/${PV}/${P}.tar.xz
	https://www.gentoo.org/assets/img/logo/gentoo-logo.png"
S="${WORKDIR}/${P}"

LICENSE="LGPL-2.1+"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="debug doc firewalld +networkmanager pcp selinux test tuned udisks"

REQUIRED_USE="${PYTHON_REQUIRED_USE}"
RESTRICT="!test? ( test )"

BDEPEND="
	>=app-crypt/mit-krb5-1.11
	>=dev-libs/glib-2.56
	>=dev-libs/json-glib-1.4
	>=net-libs/gnutls-3.6.0
	>=sys-apps/systemd-235[policykit]
	>=sys-auth/polkit-0.105[systemd]
	doc? (
		app-text/xmlto
		dev-util/gtk-doc
	)
	test? ( dev-util/gdbus-codegen )
	${PYTHON_DEPS}
	$(python_gen_cond_dep '
		dev-python/pip[${PYTHON_USEDEP}]
		test? (
			dev-python/pytest-asyncio[${PYTHON_USEDEP}]
			dev-python/pytest-cov[${PYTHON_USEDEP}]
			dev-python/pytest-timeout[${PYTHON_USEDEP}]
		)
	')
"
DEPEND="
	networkmanager? (
		firewalld? ( net-firewall/firewalld )
		net-misc/networkmanager[policykit,systemd]
	)
	pcp? ( app-metrics/pcp )
	udisks? ( sys-fs/udisks[lvm,systemd] )
	tuned? ( sys-apps/tuned )
	virtual/libcrypt:=
	${PYTHON_DEPS}
"
RDEPEND="${DEPEND}
	acct-group/cockpit-ws
	acct-group/cockpit-wsinstance
	acct-user/cockpit-ws
	acct-user/cockpit-wsinstance
	app-crypt/sscg
	dev-libs/libgudev
	net-libs/glib-networking[ssl]
	virtual/krb5
"

src_prepare() {
	default
	eaclocal
	eautoreconf
	eautomake
}

src_configure() {
	local myconf=(
		$(use_enable debug)
		$(use_enable doc)
		--with-pamdir="/$(get_libdir)/security"
		--localstatedir="${EPREFIX}/var"
	)
	econf "${myconf[@]}"
}

src_install() {
	default
	python_optimize

	if ! use selinux; then
		rm -rf "${ED}"/usr/share/cockpit/selinux || die
		rm -f "${ED}"/usr/share/metainfo/org.cockpit-project.cockpit-selinux.metainfo.xml || die
	fi
	rm -rf "${ED}"/usr/share/cockpit/{packagekit,playground,sosreport} || die
	rm -f "${ED}"/usr/share/metainfo/org.cockpit-project.cockpit-sosreport.metainfo.xml || die

	insinto /usr/share/cockpit/branding/gentoo
	doins "${FILESDIR}/branding.css"
	newins "${DISTDIR}/gentoo-logo.png" logo.png
	newins "${DISTDIR}/gentoo-logo.png" apple-touch-icon.png
	newins "${DISTDIR}/gentoo-logo.png" favicon.ico
	rm -rf "${ED}"/usr/share/cockpit/branding/{arch,centos,debian,fedora,opensuse,rhel,scientific,ubuntu} || die

	newpamd "${FILESDIR}/cockpit.pam" cockpit
	dodoc README.md AUTHORS
	keepdir /etc/cockpit/ws-certs.d/
}

pkg_postinst() {
	tmpfiles_process cockpit-ws.conf
	elog "To enable Cockpit run: systemctl enable --now cockpit.socket"
}
