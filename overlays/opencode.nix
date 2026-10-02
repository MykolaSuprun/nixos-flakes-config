# opencode (v2, the rewritten CLI) packaged from the official prebuilt npm
# binary. v2 is NOT in nixpkgs and the GitHub repo only releases v1.x — the
# npm platform package is the distribution channel (the same binary the
# official installer and `npm i -g @opencode/cli` select).
#
# History: 2026-09-29 — V1 fully retired. This overlay replaced the pinned-V1
# `opencode` (the nixpkgs-opencode-pin flake input + this file's old toolbox
# re-wrapper, both deleted) and the temporary `opencode2` attr/bin name: the
# upstream npm package's bin defines both `opencode` and `opencode2`, but we
# install ONLY `opencode`. Any script still calling `opencode2` must be
# updated (e.g. the opencode-workflow repo's plugin smoke tests).
#
# Version + hash come from the npm registry metadata for
# @opencode/cli-linux-x64 (dist.integrity is the SRI sha512 of the tarball —
# used verbatim). To bump:
#   curl -s https://registry.npmjs.org/@opencode/cli-linux-x64/latest | jq '{version, dist}'
# and update both below.
#
# The wrapper carries the dev toolbox (lib/opencode-tools.nix) so the agent's
# spawned tools resolve on PATH; OPENCODE_DISABLE_AUTOUPDATE keeps the nix
# build immutable; HERDR_AGENT lets Herdr's foreground-process detection
# recognize opencode through the wrapper.
self: super: let
  version = "2.0.22";

  # Nix system -> npm platform package suffix.
  platformMap = {
    x86_64-linux = "linux-x64";
  };

  target = platformMap.${super.stdenv.hostPlatform.system}
    or (throw "opencode: unsupported system ${super.stdenv.hostPlatform.system}");

  # SRI sha512 from the registry's dist.integrity field.
  hashes = {
    linux-x64 = "sha512-DlV1qgEDDnVqpTWMPqv7tCHCcXodzZBFaMcxjsiYdY6E5gHH2Q68JfasVksyQ1nu6m1887WQKGhOsepE+oKyYw==";
  };

  isLinux = super.stdenv.hostPlatform.isLinux;
in {
  opencode = super.stdenv.mkDerivation {
    pname = "opencode";
    inherit version;

    src = super.fetchurl {
      url = "https://registry.npmjs.org/@opencode/cli-${target}/-/cli-${target}-${version}.tgz";
      hash = hashes.${target};
    };

    # Every platform tarball unpacks to a single "package/" directory
    # containing bin/opencode (verified 2026-09-22).
    sourceRoot = "package";

    nativeBuildInputs =
      [super.makeBinaryWrapper]
      ++ super.lib.optionals isLinux [super.autoPatchelfHook];

    # The Linux binary links glibc basics only (libc/libpthread/libdl/libm +
    # ld-linux); stdenv.cc.cc.lib covers them.
    buildInputs = super.lib.optionals isLinux [super.stdenv.cc.cc.lib];

    # bun-compiled single-file executables carry an appended payload;
    # stripping would corrupt them.
    dontStrip = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 bin/opencode $out/bin/opencode
      runHook postInstall
    '';

    postInstall = ''
      # opencode wants a writable $HOME even for read-only invocations such
      # as --version; the sandbox's $HOME (/var/empty) is not.
      export HOME=$(mktemp -d)

      # The agent spawns these tools by name — the dev toolbox
      # (lib/opencode-tools.nix), plus ripgrep which opencode shells out to
      # for code search.
      wrapProgram $out/bin/opencode \
        --prefix PATH : ${super.lib.makeBinPath ([super.ripgrep] ++ import ../lib/opencode-tools.nix super)} \
        --set OPENCODE_DISABLE_AUTOUPDATE true \
        --set HERDR_AGENT "opencode"
    '';

    # Install-time smoke test: the binary must run and report our version.
    # Runs after fixupPhase so autoPatchelfHook has rewritten the dynamic
    # linker (before that, execve fails with ENOENT in the sandbox).
    doInstallCheck = super.stdenv.buildPlatform.canExecute super.stdenv.hostPlatform;
    installCheckPhase = ''
      runHook preInstallCheck
      export HOME=$(mktemp -d)
      output="$($out/bin/opencode --version)"
      echo "opencode --version: $output"
      # The binary prints "opencode v<version>" — match the version substring
      # rather than the exact string so a prefix change doesn't break the build.
      case "$output" in
        *"$version"*) ;;
        *)
          echo "version check failed: expected $version in '$output'" >&2
          exit 1
          ;;
      esac
      runHook postInstallCheck
    '';

    meta = with super.lib; {
      description = "AI coding agent built for the terminal (v2, prebuilt binary from npm)";
      homepage = "https://opencode.ai";
      changelog = "https://opencode.ai/changelog";
      license = licenses.mit;
      mainProgram = "opencode";
      platforms = attrNames platformMap;
      sourceProvenance = with sourceTypes; [binaryNativeCode];
    };
  };
}
