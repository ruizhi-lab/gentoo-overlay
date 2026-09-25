# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

DESCRIPTION="User for the libvirt D-Bus service"
KEYWORDS="~amd64 ~x86"

ACCT_USER_ID="-1"
ACCT_USER_GROUPS=( libvirtdbus libvirt )
ACCT_USER_HOME="/var/empty"
ACCT_USER_HOME_OWNER="root:root"
ACCT_USER_HOME_PERMS=0
ACCT_USER_SHELL="/sbin/nologin"

acct-user_add_deps
