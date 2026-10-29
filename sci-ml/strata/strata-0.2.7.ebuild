# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..14} )
PYTHON_REQ_USE="ssl(+)"
# Upstream builds the engine with CMAKE_BUILD_TYPE=Release (-O3, no -g) and expects that: the binary is
# packaged with a SHA-256 manifest, so it is not stripped after src_install, and a RelWithDebInfo build
# would double the installed size of something Portage cannot shrink.
CMAKE_BUILD_TYPE=Release
# Strata's HIP backend needs the ROCm 7 wave32 compiler stack (gfx1103, gfx115x and gfx120x targets).
ROCM_VERSION="7.0"

inherit cmake cuda python-single-r1 rocm

# Strata takes ggml from a pinned llama.cpp commit (third_party/ggml/VERSION.txt upstream) and builds its
# own prompt kernels and CPU experts from that exact tree: a llama.cpp release does not carry the same
# MMQ scheduler. The tree is a distfile, so a build never downloads anything.
LLAMA_COMMIT="3cf03257f219afbe7334045ff7c6a06ac68c627d"

DESCRIPTION="Inference engine and terminal for Qwen3.8-Flash-Next and other GGUF models"
HOMEPAGE="https://github.com/Niko1221/Strata"
SRC_URI="
	https://github.com/Niko1221/Strata/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/ggml-org/llama.cpp/archive/${LLAMA_COMMIT}.tar.gz
		-> llama.cpp-${LLAMA_COMMIT}.tar.gz
"
S="${WORKDIR}/Strata-${PV}"
LLAMA_S="${WORKDIR}/llama.cpp-${LLAMA_COMMIT}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+cuda hip +terminal"
REQUIRED_USE="
	?? ( cuda hip )
	hip? ( ${ROCM_REQUIRED_USE} )
	terminal? ( ${PYTHON_REQUIRED_USE} )
"
# The engine component records the SHA-256 of every file and the terminal verifies it at every start;
# stripping (or splitdebug) after src_install would break that check.
RESTRICT="strip"

# The engine links its GPU libraries at run time, so the toolkit and the ROCm stack stay in RDEPEND;
# only their headers are a build-time need.
CUDA_DEP="dev-util/nvidia-cuda-toolkit"
CDEPEND="
	cuda? (
		${CUDA_DEP}:=
		x11-drivers/nvidia-drivers
	)
	hip? (
		dev-util/hip:=
		dev-util/rocminfo
		dev-util/rocm-smi
		sci-libs/hipBLAS[${ROCM_USEDEP}]
		sci-libs/hipBLASLt[${ROCM_USEDEP}]
		sci-libs/rocBLAS[${ROCM_USEDEP}]
	)
	terminal? (
		$(python_gen_cond_dep '
			dev-python/jinja2[${PYTHON_USEDEP}]
			dev-python/numpy[${PYTHON_USEDEP}]
			>=dev-python/pillow-12[${PYTHON_USEDEP}]
			dev-python/psutil[${PYTHON_USEDEP}]
			>=dev-python/pyyaml-6.0.3[${PYTHON_USEDEP}]
			dev-python/regex[${PYTHON_USEDEP}]
			>=dev-python/requests-2.34[${PYTHON_USEDEP}]
			dev-python/textual[${PYTHON_USEDEP}]
			dev-python/tqdm[${PYTHON_USEDEP}]
			>=dev-python/truststore-0.10[${PYTHON_USEDEP}]
		')
	)
"
DEPEND="
	${CDEPEND}
	cuda? ( ${CUDA_DEP}:= )
"
RDEPEND="
	${CDEPEND}
	${PYTHON_DEPS}
"
# hipcc is the only compiler that accepts the engine's .cu sources; the terminal is plain Python.
BDEPEND="
	hip? (
		dev-util/hip
		dev-build/rocm-cmake
	)
	terminal? ( ${PYTHON_DEPS} )
"

PATCHES=( "${FILESDIR}/redact-portage-managed.patch" )

pkg_setup() {
	use terminal && python-single-r1_pkg_setup
}

engine_version() {
	local ver
	ver=$(sed -n 's/^project(strata VERSION \([0-9][0-9.]*\).*/\1/p' "${S}/CMakeLists.txt")
	[[ -n ${ver} ]] || die "could not read the engine version from CMakeLists.txt"
	echo "${ver}"
}

src_configure() {
	local mycmakeargs=(
		-DSTRATA_BUILD_TESTS=OFF
		# upstream's release engine is portable: an AVX2 baseline instead of whatever CPU compiled it
		-DSTRATA_PORTABLE=ON
		# the pinned llama.cpp tree instead of FetchContent
		-DSTRATA_GGML_DIR="${LLAMA_S}"
	)

	if use hip; then
		# cmake/hip_backend.cmake refuses every architecture it does not know, so the list comes from
		# the eclass's USE_EXPAND and never from a probe of the build host.
		mycmakeargs+=(
			-DSTRATA_ENABLE_CUDA=OFF
			-DSTRATA_ENABLE_HIP=ON
			# the AMD path's MMQ prompt kernels; CUDA-only option, an error with HIP off
			-DSTRATA_PREFILL_MMQ=ON
			-DCMAKE_HIP_ARCHITECTURES="$(get_amdgpu_flags)"
		)
		export ROCM_TARGET_LST="${T}/rocm-targets.lst"
		printf '%s\n' "${AMDGPU_TARGETS[@]}" > "${ROCM_TARGET_LST}" || die
		rocm_add_sandbox
	elif use cuda; then
		mycmakeargs+=( -DSTRATA_ENABLE_CUDA=ON -DSTRATA_ENABLE_HIP=OFF )
		# nvcc enumerates the build host's cards unless the list is given; the target's is the user's
		# business, so an unset list keeps upstream's default (sm_86, sm_89 and the sm_120 PTX).
		if [[ -n ${CMAKE_CUDA_ARCHITECTURES} ]]; then
			mycmakeargs+=( -DCMAKE_CUDA_ARCHITECTURES="${CMAKE_CUDA_ARCHITECTURES}" )
		else
			einfo "Building for upstream's default CUDA architectures (sm_86, sm_89, sm_120 PTX)."
			einfo "Set CMAKE_CUDA_ARCHITECTURES in /etc/portage/env/${PN} to target another card."
		fi
		local -x CUDAHOSTCXX="$(cuda_gccdir)"
		cuda_add_sandbox
		addpredict "/dev/char/"
	fi

	cmake_src_configure
}

src_compile() {
	# The default target also carries the parity and benchmark programs the terminal never starts.
	if use hip; then
		cmake_build strata strata-device
	else
		cmake_build strata
	fi
}

# The component folder holds one directory per engine, <version>-<platform>-<backend>/, holding the
# binaries, BUILD.json and engine-component.json (schema 2: the SHA-256 and size of every file, the
# architecture list, the oldest driver, the build id). Strata resolves and verifies it at every start,
# so the packaging helper upstream ships is what builds it, and this ebuild only has to name the
# libraries that come from the GPU driver or the ROCm packages instead of being bundled.
package_engine() {
	local -a arches=( "$@" )
	local backend stage arch_json
	backend=$(usex hip hip cuda)
	stage="${T}/engine-stage"

	mkdir -p "${stage}" || die
	cp "${BUILD_DIR}/strata" "${stage}/" || die
	use hip && cp "${BUILD_DIR}/strata-device" "${stage}/" || die

	arch_json=$(printf '"%s", ' "${arches[@]}")
	cat > "${stage}/BUILD.json" <<-EOF || die
	{
	 "version": "$(engine_version)",
	 "source": "Gentoo sci-ml/strata-${PV}",
	 "portable": true,
	 "archs": [${arch_json%, }]
	}
	EOF

	# The engine links its GPU libraries from RDEPEND; the helper refuses a package that imports
	# something neither bundled nor owned by the OS or a driver, so they are named explicitly.
	local -a allow=( --allow-lib libcuda.so.1 --allow-lib libnvidia-ml.so.1 )
	local lib bin
	while read -r lib; do
		case ${lib} in
			libamdhip64.so.*|libamd_comgr.so.*|libhsa-runtime64.so.*|libhipblas.so.*|libhipblaslt.so.*|libhiprtc.so.*|librocblas.so.*)
				allow+=( --allow-lib "${lib}" ) ;;
			libcublas.so.*|libcublasLt.so.*)
				allow+=( --allow-lib "${lib}" ) ;;
		esac
	done < <(
		for bin in "${stage}/strata" "${stage}/strata-device"; do
			[[ -f ${bin} ]] || continue
			readelf -d "${bin}" | sed -n 's/.*(NEEDED).*\[\(.*\)\]/\1/p'
		done | sort -u
	)

	local -a archargs=()
	local arch
	for arch in "${arches[@]}"; do
		archargs+=( --arch "${arch}" )
	done

	# A HIP package must record which hipBLASLt it was built against: the terminal matches its tuning
	# tables on that number and refuses a package without it. Upstream reads
	# <rocm>/include/hipblaslt/hipblaslt-version.h, but hipBLASLt installs the header flat as
	# <prefix>/include/hipblaslt-version.h, so the number is taken from there and passed as --version.
	# The tables themselves come from tools/hip in the source tree; an architecture without one for
	# this version keeps plain hipBLAS, which stage_tuning.py reports.
	if use hip; then
		local hdr="${ESYSROOT}/usr/include/hipblaslt-version.h"
		[[ -f ${hdr} ]] || die "hipBLASLt headers are missing (${hdr}); sci-libs/hipBLASLt is a dependency"

		local -a ver=( 0 0 0 )
		local comp
		for comp in MAJOR MINOR PATCH; do
			local v
			v=$(sed -n "s/^#define[[:space:]]*HIPBLASLT_VERSION_${comp}[[:space:]]\+\([0-9]\+\).*/\1/p" "${hdr}")
			[[ -n ${v} ]] || die "could not read HIPBLASLT_VERSION_${comp} from ${hdr}"
			case ${comp} in
				MAJOR) ver[0]=${v} ;;
				MINOR) ver[1]=${v} ;;
				PATCH) ver[2]=${v} ;;
			esac
		done
		local ver_num=$(( ver[0] * 100000 + ver[1] * 100 + ver[2] ))
		einfo "hipBLASLt ${ver[0]}.${ver[1]}.${ver[2]} (${ver_num})"

		python3 -I packaging/stage_tuning.py \
			--stage "${stage}" \
			--archs "${arches[*]}" \
			--version "${ver_num}" \
			--tables "${S}/tools/hip" || die
	fi

	# --no-picture-reader: strata-vision is a second CMake project that builds ggml again for the CPU and
	# once more for the GPU. Without it Strata answers text only, which pkg_postinst says.
	python3 -I packaging/package_engine.py \
		--src "${stage}" \
		--backend "${backend}" \
		--version "$(engine_version)" \
		--platform linux-x86_64 \
		--out "${ED}/usr/$(get_libdir)/${PN}/components/engine" \
		--build-id "gentoo-${PF}" \
		--no-picture-reader \
		"${archargs[@]}" "${allow[@]}" || die
}

install_terminal() {
	# The terminal is the layout packaging/package_terminal.py builds, minus the private interpreter:
	# the installed Python runs it. Everything it resolves is relative to the folder holding strata.py.
	local root="/usr/share/${PN}"
	local mod

	insinto "${root}"
	doins strata.py requirements.txt requirements-monitor.txt

	for mod in strata_cli strata_control serve; do
		insinto "${root}/${mod}"
		doins -r "${mod}/."
		# the API server's tests are shipped upstream but never run from an installed copy
		rm -f "${ED}${root}/${mod}"/test_*.py || die
	done

	# strata_control.gguf_preflight imports tools.gguf_reader, and the drafter packer the terminal uses
	# needs the other two; the install root is on sys.path, so `tools` has to look like a package.
	insinto "${root}/tools"
	doins tools/gguf_reader.py tools/strata_tokenizer.py tools/dflash2_pack.py
	insinto "${root}/ref"
	doins ref/load.py

	insinto "${root}/data"
	doins data/gguf_fingerprints.json data/draft_vocab.bin data/draft_vocab_cyrillic.bin \
		data/draft_vocab_en.bin data/draft_vocab_fr.bin data/expert-profile.bin \
		data/expert-profile-coder.bin

	insinto "${root}/bench/prompts"
	doins -r bench/prompts/standard-v1

	# strata_cli.version() reads these; an installed terminal reports the engine build it was merged with
	echo "$(engine_version)" > "${T}/VERSION" || die
	echo "gentoo-${PF}" > "${T}/COMMIT" || die
	insinto "${root}"
	doins "${T}/VERSION" "${T}/COMMIT"

	exeinto /usr/bin
	newexe "${FILESDIR}/${PN}-launcher.sh" ${PN}
	python_fix_shebang "${ED}/usr/bin/${PN}"
	python_optimize "${ED}${root}"

	# The launcher and serve/server.py resolve the API server's web assets and the terminal's modules
	# from a fixed libexec path; /usr/share is the only place a merged package may keep them.
	dosym "../../share/${PN}" "/usr/$(get_libdir)/${PN}"
}

src_install() {
	local -a arches=()
	if use hip; then
		arches=( "${AMDGPU_TARGETS[@]}" )
	else
		local arch norm
		for arch in ${CMAKE_CUDA_ARCHITECTURES:-86 89 120}; do
			norm=${arch%%-*}
			norm=${norm#sm_}
			norm=${norm#compute_}
			arches+=( "sm_${norm}" )
		done
	fi
	package_engine "${arches[@]}"

	use terminal && install_terminal

	dodoc README.md
	docinto "${PN}"
	dodoc docs/MANAGEMENT_PROTOCOL.md docs/AMD_HIP.md docs/INSTALL.md
	dodoc "${FILESDIR}/README.gentoo"
}

pkg_postinst() {
	if use hip; then
		elog "The engine was built for: ${AMDGPU_TARGETS[*]}."
		elog
	fi
	elog "Run 'strata launch' to pick and download a model, or 'strata serve' for the"
	elog "OpenAI/Anthropic-compatible API on localhost. Models and run configs live in the"
	elog "calling user's ~/.local/share/strata."
	elog
	elog "The engine is a system component under /usr/$(get_libdir)/${PN}/components,"
	elog "upgraded with Portage. 'strata install' and 'strata update' refuse to run and name"
	elog "Portage instead; export STRATA_PACKAGE_MANAGED=0 with a writable"
	elog "STRATA_COMPONENTS_DIR to run a per-user engine."
	if ! use terminal; then
		elog
		elog "USE=\"-terminal\" is set: only the engine component was installed."
	fi
	elog
	ewarn "The picture reader (strata-vision) is not built, so Strata answers text only."
}
