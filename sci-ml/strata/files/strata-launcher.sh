#!/bin/sh
# Launcher for the Strata terminal installed by sci-misc/strata.
#
# The inference engine is a "component package" that Strata verifies (SHA-256 of every
# file, recorded in engine-component.json) and then starts. This ebuild generates that
# package from the binaries it builds and installs it under /usr/lib/strata/components,
# so the engine and the terminal always belong to the same emerge.
#
# Strata resolves the component folder from STRATA_COMPONENTS_DIR; the /usr default is
# per-user, hence the override below.
#
# Run configs and models are the user's: they live in ~/.local/share/strata. Without
# STRATA_INSTALL_DIR strata would default to <components>/../install, which is
# root-owned here, so both install and data folders are pointed at the caller's XDG
# data directory unless the user already set them.
#
# STRATA_PACKAGE_MANAGED=1 makes `strata install` and `strata update` refuse and name
# Portage instead (files/redact-portage-managed.patch). Export it as 0 together with a
# writable STRATA_COMPONENTS_DIR to experiment with a per-user engine.
set -eu

: "${STRATA_COMPONENTS_DIR:=/usr/lib/strata/components}"
: "${XDG_DATA_HOME:=${HOME}/.local/share}"
: "${STRATA_INSTALL_DIR:=${XDG_DATA_HOME}/strata}"
: "${STRATA_DATA_DIR:=${XDG_DATA_HOME}/strata}"
: "${STRATA_PACKAGE_MANAGED:=1}"
export STRATA_COMPONENTS_DIR STRATA_INSTALL_DIR STRATA_DATA_DIR STRATA_PACKAGE_MANAGED

exec python3 /usr/share/strata/strata.py "$@"
