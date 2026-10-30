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

inherit cmake cuda multiprocessing python-single-r1 rocm toolchain-funcs

# Strata takes ggml from a pinned llama.cpp commit (third_party/ggml/VERSION.txt upstream) and builds its
# own prompt kernels and CPU experts from that exact tree: a llama.cpp release does not carry the same
# MMQ scheduler. The tree is a distfile, so a build never downloads anything.
LLAMA_COMMIT="3cf03257f219afbe7334045ff7c6a06ac68c627d"

DESCRIPTION="Inference engine and terminal for Qwen3.8-Flash-Next"
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
# ~arm64 (the DGX Spark builds) is left out until someone has merged this there: the engine, the
# reader and the component platform key are all in place, but nothing has run it on that hardware.
KEYWORDS="~amd64"
IUSE="+cuda hip +terminal +vision"
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
			>=dev-python/rich-14[${PYTHON_USEDEP}]
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

src_prepare() {
	# cmake_src_prepare applies PATCHES and then eapply_user, which Portage requires of every
	# src_prepare(). The patch makes `strata install` and `strata update` refuse under Portage.
	cmake_src_prepare
}

pkg_setup() {
	use terminal && python-single-r1_pkg_setup
}

# The CUDA architectures the engine is compiled for. A binary without code for the user's card stops
# at startup, so this is the user's choice: CMAKE_CUDA_ARCHITECTURES in /etc/portage/env/strata, or
# CUDAARCHS in make.conf (what CUDA's own tooling reads). Both are honoured; the more specific one wins.
#
# Without either, the engine is built for the NVIDIA cards in the build host, read from the driver.
# That is the only default that is right on an arbitrary machine: any fixed list would suit one host
# and produce a binary that stops on the next one. It ties the result to this host, which is what
# someone building for themselves wants; name the cards to build for another machine.
#
# The value is always a concrete list, never CMake's "native", because the same string also describes
# the package in BUILD.json and a manifest cannot say "native".
cuda_architectures() {
	# Called from src_configure, the reader build and src_install; the fallback notice belongs once,
	# in src_configure, and the three calls must return the same value.
	if [[ -n ${_STRATA_CUDA_ARCHS} ]]; then
		echo "${_STRATA_CUDA_ARCHS}"
		return
	fi

	local archs="${CMAKE_CUDA_ARCHITECTURES:-${CUDAARCHS}}"

	if [[ ${archs} == native || -z ${archs} ]]; then
		local caps
		caps=$(nvidia-smi --query-gpu=compute_cap --format=csv,noheader 2>/dev/null) \
			|| die "no CUDA architecture is configured and nvidia-smi did not answer; set \
CMAKE_CUDA_ARCHITECTURES in /etc/portage/env/${PN}, e.g. \"120-real\""

		# 12.0 -> sm_120; a card whose capability has no matching -real code (an arch newer than the
		# toolkit knows) keeps the PTX as well, which the driver can compile at load time
		local cap
		archs=""
		for cap in ${caps}; do
			archs+="${archs:+;}${cap/./}-real"
		done
		[[ -n ${archs} ]] || die "nvidia-smi reported no compute capability"

		ewarn "No CMAKE_CUDA_ARCHITECTURES or CUDAARCHS is set: building for the cards in this"
		ewarn "machine (${archs}). To build for another machine, name its cards in"
		ewarn "/etc/portage/env/${PN}, e.g. CMAKE_CUDA_ARCHITECTURES=\"86-real\" or"
		ewarn "\"89-real;120-real\"."
	fi

	_STRATA_CUDA_ARCHS=${archs}
	echo "${archs}"
}

# The component's platform key, as strata_control.targets.host_platform() spells it: the terminal
# only starts a package whose platform matches this machine.
engine_platform() {
	case $(tc-arch) in
		amd64)  echo "linux-x86_64" ;;
		arm64)  echo "linux-aarch64" ;;
		*)      die "${CATEGORY}/${PN} has no engine platform for $(tc-arch)" ;;
	esac
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
		mycmakeargs+=(
			-DSTRATA_ENABLE_CUDA=ON
			-DSTRATA_ENABLE_HIP=OFF
			-DCMAKE_CUDA_ARCHITECTURES="$(cuda_architectures)"
		)
		local -x CUDAHOSTCXX="$(cuda_gccdir)"
		cuda_add_sandbox
		addpredict "/dev/char/"
	fi

	# The architecture list the component manifest records: computed once here, from the same value
	# CMake was given, so src_install never has to look at the machine again.
	package_archs=()
	if use hip; then
		package_archs=( "${AMDGPU_TARGETS[@]}" )
	else
		local arch norm arch_list
		arch_list=$(cuda_architectures)
		# ';'-separated (or spaced by hand), so split on both
		for arch in ${arch_list//;/ }; do
			norm=${arch%%-*}
			norm=${norm#sm_}
			norm=${norm#compute_}
			package_archs+=( "sm_${norm}" )
		done
	fi

	cmake_src_configure
}

# The picture reader, tools/vision/strata-vision: its own CMake project, because it links llama.cpp's
# mtmd beside the engine's ggml. It is built for the same architectures as the engine on purpose: a
# reader carried over from another build dies with "device kernel image is invalid" on a card the
# engine itself handles (#3669), and package_engine.py refuses such a package.
#
# A CUDA build has one reader, strata-vision, which reads on the GPU when started with --gpu and on the
# CPU otherwise. A HIP build has two, exactly as upstream's own packaging ships them: the CPU reader
# strata-vision, which starts on every PC, and strata-vision-hip for the card, which the terminal
# prefers when the HIP runtime loads.
#
# The HIP project renames its single target to strata-vision-hip, so the two readers come from two
# configure runs of the same project (upstream's packaging/build_hip_linux.sh does the same): one with
# the HIP backend on, one with it off.
build_vision_project() {
	local build="$1"
	shift

	# A second configure of a second project: cmake_src_configure() would reuse BUILD_DIR, so this one
	# is invoked directly, the way upstream's packaging/build_*.sh does it.
	local -x CMAKE_BUILD_TYPE=Release
	if use cuda; then
		local -x CUDAHOSTCXX="$(cuda_gccdir)"
	fi

	# -DSTRATA_PORTABLE=ON keeps the reader on an AVX2 baseline, like the engine, instead of the build
	# host's instruction set.
	cmake -S "${S}/tools/vision" -B "${build}" -G Ninja \
		-DCMAKE_BUILD_TYPE=Release \
		-DLLAMA_DIR="${LLAMA_S}" \
		-DSTRATA_PORTABLE=ON \
		"$@" || die "configuring strata-vision (${build##*/}) failed"

	cmake --build "${build}" --target strata-vision -j "$(makeopts_jobs)" \
		|| die "building strata-vision (${build##*/}) failed"
}

compile_vision() {
	local -a archargs=()

	if use hip; then
		export ROCM_TARGET_LST="${T}/rocm-targets-vision.lst"
		printf '%s\n' "${AMDGPU_TARGETS[@]}" > "${ROCM_TARGET_LST}" || die
		rocm_add_sandbox
		archargs=(
			-DSTRATA_VISION_HIP=ON
			-DSTRATA_VISION_HIP_ARCHS="$(get_amdgpu_flags)"
			-DCMAKE_HIP_COMPILER="$(hipconfig -l)/clang++"
		)
	elif use cuda; then
		archargs=(
			-DSTRATA_VISION_CUDA=ON
			# ggml-cuda wants NCCL for multi-GPU collectives, which a single-card reader never uses
			-DGGML_CUDA_NCCL=OFF
		)
		# The reader is built for the same architectures as the engine: a reader without code for the
		# card dies where the engine runs (#3669), and package_engine.py refuses such a package.
		archargs+=( -DCMAKE_CUDA_ARCHITECTURES="$(cuda_architectures)" )
	fi

	if use cuda; then
		cuda_add_sandbox
		addpredict "/dev/char/"
	fi

	build_vision_project "${WORKDIR}/vision_build" ${archargs[@]+"${archargs[@]}"}

	if use hip; then
		# the CPU fallback: the same project with no GPU backend at all
		build_vision_project "${WORKDIR}/vision_build_cpu" -DSTRATA_VISION_HIP=OFF
	fi
}

src_compile() {
	# The default target also carries the parity and benchmark programs the terminal never starts.
	if use hip; then
		cmake_build strata strata-device
	else
		cmake_build strata
	fi

	use vision && compile_vision
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
	if use hip; then
		cp "${BUILD_DIR}/strata-device" "${stage}/" || die
	fi

	# The readers, and the architectures they were built for: package_engine.py refuses a CUDA package
	# whose reader does not cover the engine's architectures, so BUILD.json records vision_archs.
	local vision_json=""
	if use vision; then
		if use hip; then
			# the HIP project names its single target strata-vision-hip; the CPU reader is the second run
			cp "${WORKDIR}/vision_build/bin/strata-vision-hip" "${stage}/" || die
			cp "${WORKDIR}/vision_build_cpu/bin/strata-vision" "${stage}/" || die
		else
			cp "${WORKDIR}/vision_build/bin/strata-vision" "${stage}/" || die
		fi
		vision_json=", \"vision_archs\": \"$(printf '%s;' "${arches[@]}" | sed 's/;$//')\""
	fi

	arch_json=$(printf '"%s", ' "${arches[@]}")
	cat > "${stage}/BUILD.json" <<-EOF || die
	{
	 "version": "$(engine_version)",
	 "source": "Gentoo sci-ml/strata-${PV}",
	 "portable": true,
	 "archs": [${arch_json%, }]${vision_json}
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
			libcudart.so.*|libcublas.so.*|libcublasLt.so.*|libcufft.so.*|libcurand.so.*|libcusparse.so.*|libcusolver.so.*|libnvrtc.so.*|libnvJitLink.so.*)
				allow+=( --allow-lib "${lib}" ) ;;
		esac
	done < <(
		for bin in "${stage}"/*; do
			[[ -f ${bin} && -x ${bin} ]] || continue
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

	# A package without the reader answers text only; package_engine.py says so itself when --src has no
	# strata-vision, so --no-picture-reader is not needed either way.
	python3 -I packaging/package_engine.py \
		--src "${stage}" \
		--backend "${backend}" \
		--version "$(engine_version)" \
		--platform "$(engine_platform)" \
		--out "${ED}/usr/lib/${PN}/components/engine" \
		--build-id "gentoo-${PF}" \
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

	# The launcher is a POSIX shell script that finds an interpreter and execs strata.py, so it keeps
	# its #!/bin/sh: python_fix_shebang is for Python scripts and refuses any other shebang. The
	# modules themselves are byte-compiled below.
	exeinto /usr/bin
	newexe "${FILESDIR}/${PN}-launcher.sh" ${PN}
	python_optimize "${ED}${root}"

	# The terminal resolves its modules, its web assets and tools/ from the folder holding strata.py.
	# It is installed under /usr/share, so the launcher points at it there; nothing else claims that
	# path, and the engine's component folder below /usr/lib/${PN} stays a real directory.
	dosym "../../share/${PN}" "/usr/lib/${PN}/terminal"
}

src_install() {
	# package_archs was filled in src_configure from the same list the engine and the reader were
	# built with, so BUILD.json's archs and vision_archs describe what was compiled, not a guess.
	package_engine "${package_archs[@]}"

	use terminal && install_terminal

	dodoc README.md
	docinto "${PN}"
	dodoc docs/AMD_HIP.md docs/INSTALL.md docs/MANAGEMENT_PROTOCOL.md docs/TERMINAL_LAUNCH.md
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
	elog "The engine runs Qwen3.8-Flash-Next only: 'strata launch' offers its GSQ-RCO,"
	elog "Q2_0 and UD quantizations, and 'strata models import' refuses any other GGUF"
	elog "file, naming llama-server instead. Use sci-misc/kvmem-llama-cpp or"
	elog "sci-misc/prism-llama-cpp for models of another family or size."
	elog
	elog "The engine is a system component under /usr/lib/${PN}/components,"
	elog "upgraded with Portage. 'strata install' and 'strata update' refuse to run and name"
	elog "Portage instead; export STRATA_PACKAGE_MANAGED=0 with a writable"
	elog "STRATA_COMPONENTS_DIR to run a per-user engine."
	if ! use terminal; then
		elog
		elog "USE=\"-terminal\" is set: only the engine component was installed."
	fi
	if ! use vision; then
		elog
		ewarn "USE=\"-vision\" is not set: the package carries no picture reader"
		ewarn "(strata-vision), so Strata answers text only."
	fi
}
