# Agent Guidelines

These instructions apply to the entire `ruizhi-overlay` repository. Preserve
unrelated user changes and follow the existing package style unless a task
explicitly requires otherwise.

## Language

- Write all repository comments and documentation in English. This includes
  source-code comments, ebuild comments, README and other documentation, and
  patch headers.
- Write GitHub issue and pull request comments, commit messages, and other
  content published to GitHub in English.

## Overlay workflow

- Use EAPI 8 for new ebuilds unless an upstream or Gentoo requirement calls for
  a newer EAPI.
- Every package must have a valid `metadata.xml`. Keep `Manifest` files current;
  this repository uses thin, unsigned manifests.
- Use `pkgdev manifest` to update manifests and `pkgcheck scan` for policy and
  QA checks. Also run `xmllint --noout metadata.xml` and `git diff --check`.
- When `pkgcheck` cannot write its default cache, set a task-specific
  `XDG_CACHE_HOME` under `/tmp`.
- An actual build of a meaningful source package can help catch regressions,
  preferably in the existing `docker-gentoo:latest` image, but local Docker
  validation is optional. Do not describe a configure-only check as a
  successful build.
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

- Verify dependency package names, versions, and USE requirements against
  authoritative sources before adding or changing them. Use the software
  project's official documentation or build metadata for upstream requirements,
  and the Gentoo or GURU repository for package atoms, available versions, and
  USE flags. Do not infer package names or version constraints from memory.
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

### ComfyUI

- Package location: `media-gfx/comfyui`; its bundled runtime assets are packaged
  as `dev-python/comfyui-embedded-docs`,
  `dev-python/comfyui-frontend-package`, and
  `dev-python/comfyui-workflow-templates`.
- Keep those asset package versions aligned with the exact pins in the matching
  ComfyUI release's upstream `requirements.txt`. Do not bump them independently
  to their newest PyPI versions; update the pins together when bumping ComfyUI.
- The PyPI entries in `.github/scripts/check-updates.sh` are informational for
  release tracking. A newer asset release alone does not justify changing its
  ebuild while ComfyUI still pins the current version.
- `comfy-kitchen` and `comfy-aimdo` are also exact-pinned runtime dependencies
  in current ComfyUI releases. Keep their ebuilds aligned with the matching
  `requirements.txt`; build them from upstream sources, not published wheels.
  Include upstream submodule revisions as explicit distfiles so builds do not
  fetch code dynamically. Forward ComfyUI's CUDA/ROCm USE selection to
  `comfy-kitchen`.
- `comfy-angle` appears in the upstream non-essential dependencies list. Do not
  make it a hard dependency; its upstream build retrieves Chromium ANGLE and
  depot-tools sources dynamically, so package it separately only after those
  inputs can be pinned and built offline.

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

- Package locations: `app-admin/cockpit` and `app-admin/cockpit-machines`.
- Cockpit Machines requires a Cockpit bridge version compatible with upstream's
  minimum; do not assume its release number must match the Cockpit Machines PV.
- `libvirt-dbus` is an optional backend. Cockpit Machines can use virsh when it
  is absent, so keep it as a QA/integration note rather than a hard dependency.
- Follow upstream stable GitHub releases. Release tags are valid Gentoo
  versions, so use the `github` update-check type without a version prefix.
- Preserve Cockpit's Gentoo branding assets and PAM configuration under
  `app-admin/cockpit/files/`.
- Keep optional Cockpit integrations behind their USE flags, and ensure all
  required account, service, and runtime dependencies are available from the
  configured repository masters before claiming the packages are buildable.

### Strata

- Package location: `sci-ml/strata`. Strata is an inference engine plus a Python
  terminal and API server, so it belongs in `sci-ml` (machine learning and NLP)
  rather than `sci-misc`, which is the fallback for packages that fit no other
  `sci-*` category. `sci-ml/ollama` and `sci-ml/ggml` are the neighbours.
- Strata runs one model family. `data/gguf_fingerprints.json` holds 17
  selections under the qwen, swift, coder, unsloth and gyro keys and every one
  is Qwen3.8-Flash-Next (`qwen35moe`), split into two shards with exact upstream
  file names. Do not describe the package as running arbitrary GGUF models:
  `strata models import` refuses anything else, including another Qwen3.8 size
  such as the 27B (`qwen35`), with "this model type is not supported by the
  Strata engine". DeepSeek-V4.1 needs `STRATA_BUILD_DSV41=ON`, which this
  package does not build, so it is not available here either. Users with other
  models want `sci-misc/kvmem-llama-cpp`, `sci-misc/prism-llama-cpp` or
  `sci-misc/llama-cpp` from guru.
- Version bumps follow upstream tags, not the release list. Upstream ships
  patch releases as tags only: `v0.2.7.1` is 127 commits newer than `v0.2.7`
  and is newer than the `v0.2.7` GitHub release, whose notes fold the 0.2.7.1
  section in. Always compare `tags` before bumping, and check which tag the
  tarball actually corresponds to.
- Because of that, the `github` update-check type in
  `.github/scripts/check-updates.sh` compares against releases and will sit
  quietly on an older PV once a release has a newer tag-only successor. Treat
  its silence as "no newer release", not "current": confirm against the tag
  list when touching the package.
- ggml comes from the llama.cpp commit pinned in upstream's
  `third_party/ggml/VERSION.txt`. When bumping, re-read that file and update
  `LLAMA_COMMIT`: leaving `STRATA_GGML_DIR` unset makes CMake fetch the tree
  over the network at configure time, which fails in the build sandbox, and a
  different commit changes the MMQ scheduler the engine's own kernels are
  written against. Keep the pinned tree as a distfile and pass
  `-DSTRATA_GGML_DIR` so no fetch happens.
- Do not add a `system-ggml` USE flag or link against `sci-ml/ggml`. The engine
  links ggml statically from its pinned tree and installs no headers or
  libraries, so it already coexists with `sci-ml/ggml` and `sci-misc/llama-cpp`;
  using the system library would break that and mix incompatible versions.
- The engine is installed as the component package the terminal verifies
  (`<version>-<platform>-<backend>/` holding `engine-component.json`, which
  records the SHA-256 of every file). Keep `RESTRICT="strip"`; stripping or
  splitdebug rewrites the binaries after `src_install` and the terminal then
  refuses to start them. Build the package with upstream's own
  `packaging/package_engine.py` rather than reproducing the manifest by hand.
- Never call `cmake --install`; only `cmake --build` and copy the programs. That
  is what keeps ggml and llama out of `/usr/include` and `/usr/$(get_libdir)`.
- `USE="vision"` builds `tools/vision` into the picture reader. Build it from
  the same architecture list as the engine and record that list as
  `vision_archs` in `BUILD.json`: `package_engine.py` refuses a CUDA package
  whose reader does not cover the engine's architectures, and a reader carried
  over from another build dies on a card the engine itself handles.
- On HIP the vision project renames its only target to `strata-vision-hip`, so
  the CPU fallback and the GPU reader come from two configure runs of the same
  project, as upstream's `packaging/build_hip_linux.sh` does. A single run
  yields only the GPU reader.
- `sci-libs/hipBLASLt` installs `hipblaslt-version.h` flat as
  `<prefix>/include/hipblaslt-version.h`, but upstream's
  `packaging/stage_tuning.py` looks under `include/hipblaslt/`. Read the
  version from the flat header and pass it with `--version` instead of relying
  on `--rocm`.
- Upstream's HIP backend refuses architectures it does not know
  (`cmake/hip_backend.cmake`). Take the target list from `rocm.eclass`'s
  `amdgpu_targets_*` USE_EXPAND so it matches the installed ROCm, and never let
  CMake or hipcc probe the build host's cards.
- CUDA builds take `CMAKE_CUDA_ARCHITECTURES` from `/etc/portage/env` rather
  than upstream's default (sm_86, sm_89 and the sm_120 PTX), because a binary
  without code for the user's card stops at startup.
- The terminal's file set is the one `packaging/package_terminal.py` stages:
  `strata.py`, `strata_cli`, `strata_control`, `serve`, `tools/` (the
  `TOOLS_SUBSET` three, since `strata_control` imports `tools.*` from the
  install root), `ref/load.py`, `data/`, `bench/prompts/standard-v1` and the two
  docs. Drop the API server's `test_*.py` modules. Re-check that list when
  bumping: a missing module fails at run time, not at build time.
- Keep `files/redact-portage-managed.patch`, which makes `strata install` and
  `strata update` refuse under Portage and name emerge instead. Re-derive the
  hunks against each new tarball with `patch --dry-run --fuzz=0`; upstream
  rewrites these functions often, and the reference ebuilds in the wild carry
  stale versions.
- The launcher must keep the component folder at `/usr/lib/strata/components`
  and point the install and data folders at the caller's XDG data directory.
  Strata otherwise derives them from the component folder, which is root-owned
  here, and `strata install`/`update` need those to be the user's own.
- Do not install the terminal under a path that the component folder also
  lives in: `/usr/lib/strata` must stay a real directory holding `components/`,
  with the Python code in `/usr/share/strata`.
