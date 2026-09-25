# Agent Guidelines

These instructions apply to the entire `ruizhi-overlay` repository. Preserve
unrelated user changes and follow the existing package style unless a task
explicitly requires otherwise.

## Overlay workflow

- Use EAPI 8 for new ebuilds unless an upstream or Gentoo requirement calls for
  a newer EAPI.
- Every package must have a valid `metadata.xml`. Keep `Manifest` files current;
  this repository uses thin, unsigned manifests.
- Use `pkgdev manifest` to update manifests and `pkgcheck scan` for policy and
  QA checks. Also run `xmllint --noout metadata.xml` and `git diff --check`.
- When `pkgcheck` cannot write its default cache, set a task-specific
  `XDG_CACHE_HOME` under `/tmp`.
- Test meaningful source packages with an actual build, preferably in the
  existing `docker-gentoo:latest` image. A successful configure step alone is
  not a sufficient build test.
- When bumping a package, remove an ebuild that is genuinely superseded. Keep a
  live `9999` ebuild when it is intentionally offered alongside releases.
- Add new release packages to `.github/scripts/check-updates.sh` when upstream
  provides a reliable machine-readable version source. Test unusual upstream
  tag-to-PV mappings so the scheduled checker does not report false updates.
- If an ebuild that has already been published needs packaging changes, create
  an incremented Gentoo revision such as `-r1`; do not silently alter the
  published revision. This does not apply while a new ebuild is still being
  prepared and has not been published.
- After completing an overlay update, commit the intended changes and push them
  to the configured remote. Never include unrelated or generated files in that
  commit.

## Dependencies and USE flags

- Classify dependencies correctly: build-host tools belong in `BDEPEND`, build
  headers/libraries in `DEPEND`, and runtime requirements in `RDEPEND`.
- Check inherited eclasses before declaring dependencies they already provide.
  In particular, `ecm.eclass` supplies `extra-cmake-modules` in `BDEPEND`.
- Prefer Gentoo global USE flag names. Use the global uppercase `X` flag for
  X11 support, not a package-local `x11` flag.
- For Wayland-first packages that can optionally build for X11, use
  `IUSE="+wayland X"` and an appropriate `REQUIRED_USE`, unless upstream support
  requires a different arrangement.
- Do not add hard dependencies between visual themes and compatible KWin
  effects unless one is technically required to build or run the other.

## Patches

- Make deterministic source-tree edits during `src_prepare()`, not
  `src_compile()`. A small build-flag adjustment may use `sed` when the expected
  input is checked first and a mismatch calls `die`.
- Dynamic desktop-entry values derived from USE flags may be edited during the
  install phase with validated `sed` substitutions. A complete replacement
  desktop file should live under `files/` and be installed with `newmenu`.
- Keep source compatibility fixes as dedicated files under `files/` and apply
  them through `PATCHES`. Do not hide such changes in ad-hoc `sed` commands.
- Patch headers should explain the purpose and include author/date, a
  `[PATCH]` subject, and upstream status or source when known.
- Generate hunks against the exact release tarball and verify them with
  `patch --dry-run --fuzz=0`. Patches that require fuzz must be corrected.
- Backport patches should normally apply only to affected release ebuilds, not
  to `9999` after the fix has landed upstream.
- Remove obsolete backports when a later release contains the fix.

## Network and Docker

- When GitHub access needs a proxy, use the local HTTP proxy
  `http://127.0.0.1:10808`. Apply it through command environment variables;
  never hard-code a local proxy into an ebuild, `SRC_URI`, or repository file.
- Docker containers need host networking to reach that loopback proxy, for
  example `docker run --network host ...`.
- Fetch DataGrip and WeChat source archives without the configured proxy.
- Prefer read-only bind mounts for this overlay during container builds. Use
  temporary directories for distfiles, Portage state, logs, and generated
  packages.
- The `docker-gentoo:latest` image may not have the GURU repository configured.
  For local tests, register this overlay with a temporary `repos.conf` using
  `masters = gentoo`; do not change the repository's real
  `metadata/layout.conf`, which correctly declares `masters = gentoo guru`.

## Package-specific notes

### kwin-effects-glass

- Package location: `kde-misc/kwin-effects-glass`.
- Keep both a release ebuild and `kwin-effects-glass-9999.ebuild` tracking the
  upstream `main` branch.
- The package is Wayland-first. Its CMake switches are `GLASS_WAYLAND` and
  `GLASS_X11`; expose X11 with the Gentoo `X` USE flag.
- KDecoration3 is provided by `kde-plasma/kdecoration`, not
  `kde-frameworks/kdecoration`.
- Keep compatibility backports only on affected release ebuilds, and remove
  them when a later upstream release includes the fix.

### cockpit and cockpit-machines

- Package locations: `app-admin/cockpit`, `app-admin/cockpit-machines`, and
  `app-emulation/libvirt-dbus`.
- Cockpit Machines requires a Cockpit bridge version compatible with upstream's
  minimum; do not assume its release number must match the Cockpit Machines PV.
- Keep `libvirt-dbus` as a separate runtime dependency: libvirt's D-Bus support
  and the `libvirt-dbus` service are distinct components.
- The D-Bus service runs as `libvirtdbus` and uses the `libvirt` group for
  system libvirt socket access; keep its account packages in this overlay.
- Follow upstream stable GitHub releases. Release tags are valid Gentoo
  versions, so use the `github` update-check type without a version prefix.
- Preserve Cockpit's Gentoo branding assets and PAM configuration under
  `app-admin/cockpit/files/`.
- Keep optional Cockpit integrations behind their USE flags, and ensure all
  required account, service, and runtime dependencies are available from the
  configured repository masters before claiming the packages are buildable.
