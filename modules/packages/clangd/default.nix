let
# clangd, statically linked against nixpkgs' llvm archives.
#
# Upstream publishes a prebuilt clangd, but only for x86_64-linux (the release
# zip has no aarch64 asset), and llvm-project's own aarch64-linux tarballs stop
# at 19.1.7. So on aarch64 we have to build from nixpkgs -- but nixpkgs'
# `clang-tools` has a ~973 MiB closure, of which ~706 MiB is static .a archives
# and ~320 MiB is a full gcc retained only to resolve #include <...>.
#
# Those archives are exactly what a static link wants as input, and they are
# already built and cached. So instead of stripping them out of a dynamic
# build, we link clangd against them directly: no libLLVM.so, no
# libclang-cpp.so, and no from-source llvm rebuild.
#
# --gc-sections does the heavy lifting. llvm compiles with -ffunction-sections,
# so the linker can drop every function clangd never reaches. That takes the
# binary from 83 MiB to 56 MiB -- within ~3 MiB of upstream's prebuilt, which
# gets there via LLVM_TARGETS_TO_BUILD trimming and LTO (both of which would
# require recompiling llvm). All 20 target backends survive here, so cross-
# target analysis via --target= still works.
#
# No headers are shipped at all -- not clangd's own builtin ones (stddef.h,
# stdarg.h, ...), and not libc/libstdc++. Whatever consumes this (a container,
# a dev shell) already has its own compiler on hand, which may not even be
# clang, and clangd is expected to pick that up (via a compile database or
# --query-driver) rather than fall back to headers bundled here. Without a
# resource dir, orphan files with no compile command just get "stddef.h file
# not found" from clangd's own parser -- accepted as the cost of not carrying
# a second, possibly mismatched copy of clang's builtins into every consumer.
# The 15 MiB builtin-headers copy is still used at build time, to sanity-check
# the binary itself (see installCheckPhase below).
localfunc = {
  stdenv,
  lib,
  llvmPackages,
  patchelf,
  nukeReferences,
  zlib,
}:
let
  clang = llvmPackages.clang-unwrapped;
  llvmlib = llvmPackages.libllvm.lib;

  clangMajor = lib.versions.major (lib.getVersion clang);

  # The .so's we still link against dynamically. libLLVM/libclang-cpp are
  # absent by design -- they are inside the binary now. libffi/libxml2/ncurses
  # were here too, but clangd never actually resolves a symbol against them
  # (confirmed via readelf -d NEEDED) -- nixpkgs' fixup phase already
  # shrink-rpaths them out of the closure, so keeping them as inputs was
  # dead weight.
  runtimeLibs = [
    zlib
    stdenv.cc.cc.lib
    stdenv.cc.libc
  ];
in
stdenv.mkDerivation {
  pname = "clangd";
  version = lib.getVersion clang;

  dontUnpack = true;

  nativeBuildInputs = [
    patchelf
    nukeReferences
  ];

  buildInputs = runtimeLibs;

  # Default stripping is -S -p (debug info only), which leaves ~14 MiB of
  # .symtab/.strtab in a binary this size. clangd doesn't symbolise its own
  # stack traces usefully, so strip everything.
  stripAllList = [ "bin" ];

  # clangd's real entry point is clang::clangd::clangdMain; the archive that
  # provides it has no main() of its own.
  buildPhase = ''
    runHook preBuild

    cat > clangd-main.cpp <<'MAIN_CXX'
    namespace clang {
    namespace clangd {
    int clangdMain(int argc, char **argv);
    }
    }

    int main(int argc, char **argv) { return clang::clangd::clangdMain(argc, argv); }
MAIN_CXX

    # --start-group/--end-group: these archives are mutually recursive, so the
    # linker has to revisit them until symbol resolution settles.
    $CXX -O2 -o clangd clangd-main.cpp \
      -Wl,--gc-sections -Wl,--as-needed \
      -Wl,--start-group \
        ${clang.lib}/lib/libclangd*.a \
        ${clang.lib}/lib/libclangDaemon*.a \
        ${clang.lib}/lib/libclang*.a \
      -Wl,--end-group \
      -Wl,--start-group \
        ${llvmlib}/lib/libLLVM*.a \
      -Wl,--end-group \
      -lz -lpthread -ldl -lm

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    install -m755 clangd $out/bin/clangd

    # Three store paths are baked into the binary as string constants: the
    # compiled-in resource dir, plus a darwin libLTO path and a libm-function
    # table (both dead code here). Left alone they would retain the two 846 MiB
    # llvm outputs, so nuke-refs blanks them. The resource dir ends up pointing
    # at a nonexistent /nix/store/eeee... path -- fine, since we don't ship
    # builtin headers for it to find anyway (see installCheckPhase for why).
    interp=$(patchelf --print-interpreter $out/bin/clangd)
    nuke-refs $out/bin/clangd
    patchelf --set-interpreter "$interp" \
             --set-rpath "${lib.makeLibraryPath runtimeLibs}" \
             $out/bin/clangd

    runHook postInstall
  '';

  # The failure mode of a broken clangd build is silent: it still starts and
  # prints its version, then fails on the first #include. Check at build time
  # instead, against clang.lib's own headers -- available in the sandbox as a
  # build input, never copied into $out (see installPhase for why $out ships
  # no headers at all).
  #
  # Both probes pass --resource-dir explicitly rather than relying on clangd to
  # find it on its own. Without a compile database, clangd falls back to
  # probing whatever cc/gcc/clang it finds on PATH for a "generic fallback
  # command" -- what that probe returns (and thus which headers get picked up)
  # depends on the ambient build sandbox's toolchain, not on this package, so
  # asserting on it here is asserting on the wrong thing.
  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    resourceDir="${clang.lib}/lib/clang/${clangMajor}"

    # Probes use ONLY clang's builtin headers. libc/libstdc++ headers are
    # deliberately not exercised here, so <stdio.h>/<vector> are expected to be
    # absent and must not be asserted on -- a consumer supplies those.
    cat > probe.c <<'PROBE_C'
    #include <stddef.h>
    #include <stdarg.h>
    #include <stdint.h>
    #include <limits.h>
    int main(void) { size_t n = 0; uint64_t u = 0; return (int)(n + u); }
PROBE_C

    $out/bin/clangd --version

    $out/bin/clangd --resource-dir="$resourceDir" --check=probe.c 2>&1 | tee log.probe.c
    diags=$(grep -c '^E\[' log.probe.c || true)
    if [ "$diags" != "0" ]; then
      echo "clangd reported $diags diagnostics on its own builtin headers"
      exit 1
    fi
    grep -q 'Building AST' log.probe.c

    # --gc-sections is aggressive; make sure it didn't collect a backend we
    # still want. Analysing a non-native target must keep working -- clangd
    # takes the target from the compile flags, not its own argv.
    mkdir -p cross && cp probe.c cross/
    echo "--target=x86_64-unknown-linux-gnu" > cross/compile_flags.txt
    (cd cross && $out/bin/clangd --resource-dir="$resourceDir" --check=probe.c 2>&1 | tee ../log.cross)
    grep -q 'triple x86_64-unknown-linux-gnu' log.cross || {
      echo "x86_64 backend missing: clangd did not accept the target"
      exit 1
    }
    cross=$(grep -c '^E\[' log.cross || true)
    if [ "$cross" != "0" ]; then
      echo "cross-target analysis regressed: $cross diagnostics"
      exit 1
    fi

    runHook postInstallCheck
  '';

  # Tripwire: llvm coming back means the static link silently went dynamic;
  # bash/linux-headers coming back means bundled headers or a wrapper crept in.
  disallowedReferences = [
    clang
    clang.lib
    llvmlib
    stdenv.cc.cc
    stdenv.cc.libc.dev
  ];

  meta = {
    description = "clangd language server, statically linked against llvm";
    mainProgram = "clangd";
    platforms = lib.platforms.linux;
  };
};
in
{
  internal.overlays.clangd = final: prev: {
    clangd = final.callPackage localfunc { };
  };
}
