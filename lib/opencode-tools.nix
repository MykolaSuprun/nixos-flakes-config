# lib/opencode-tools.nix — the dev toolbox opencode's agent can call by name:
# LSPs, formatters, linters, security scanners and CLI utilities. Consumed by
# overlays/opencode.nix (V2 build; the separate V1 and opencode2 wrapper
# overlays were retired 2026-09-29).
#
# Lives in lib/ (not overlays/) because overlays/default.nix auto-imports
# every .nix file in overlays/ as an overlay — a helper there would be
# mis-imported.
#
# Usage:
#   let opencodeTools = import ../lib/opencode-tools.nix; in
#   lib.makeBinPath (opencodeTools pkgs)
pkgs: let
  # Grouped by role for readability; the wrapper flattens them into one PATH
  # prefix.
  # Curated against the actual ~/workspaces census (2026-10-28): ts/js, python,
  # go, nix, c/c++, lua, shell, markdown, dockerfile. Language families with no
  # project markers or source files here (Rust, Java, Kotlin, Scala, C#, Swift,
  # Ruby, Haskell, Elixir, PHP, OCaml, Zig, Jsonnet, Terraform) were removed —
  # the closure cost was concentrated in exactly those (csharpier 753 MiB,
  # ktlint 636 MiB). Re-add a family only when a real project needs it.
  lsps = [
    pkgs.typescript-language-server
    pkgs.vscode-langservers-extracted # HTML/CSS/JSON
    pkgs.yaml-language-server
    pkgs.lua-language-server
    pkgs.basedpyright
    pkgs.nixd
    pkgs.gopls
    pkgs.bash-language-server
    pkgs.taplo # TOML
    pkgs.marksman # Markdown
    pkgs.clang-tools # C/C++
    pkgs.dockerfile-language-server
  ];

  formatters = [
    pkgs.alejandra # Nix
    pkgs.prettierd
    pkgs.prettier
    pkgs.ruff # Python
    pkgs.shfmt # Shell
    pkgs.stylua # Lua
    pkgs.go # gofmt
    pkgs.dprint
    pkgs.yamlfmt
    pkgs.cmake-format
    pkgs.biome
  ];

  linters = [
    pkgs.shellcheck
    pkgs.hadolint # Dockerfile
    pkgs.yamllint
    pkgs.shellharden
    pkgs.bashate
    pkgs.eslint
    pkgs.golangci-lint
    pkgs.statix # Nix
    pkgs.deadnix # Nix
    pkgs.markdownlint-cli
    pkgs.actionlint # GitHub Actions
    pkgs.cppcheck
    pkgs.cpplint
    pkgs.flawfinder # C
    pkgs.oxlint
    pkgs.stylelint # CSS
    pkgs.htmlhint
    pkgs.lychee # link checker
    pkgs.gitlint
    pkgs.vale # prose
  ];

  security = [
    pkgs.gitleaks
    pkgs.detect-secrets
    pkgs.trufflehog
    # semgrep removed 2026-10-28: semgrep-core 1.180.0 is unbuildable on the
    # pinned nixpkgs (patchelf 0.19.2 aborts in fixupPhase with
    # `Assertion 'splitIndex == -1' failed` while rewriting the prebuilt wheel
    # binary) — nixpkgs#579107 / patchelf#583, both still open upstream.
    # Re-add once nixpkgs ships a fixed semgrep-core.
    pkgs.bandit # Python
    pkgs.pip-audit
    pkgs.govulncheck
    pkgs.gosec # Go
    pkgs.revive
    pkgs.trivy
    pkgs.grype
    pkgs.syft # SBOM
    pkgs.osv-scanner
    pkgs.conftest
    pkgs.open-policy-agent
    pkgs.nuclei
  ];

  devCli = [
    pkgs.jq
    pkgs.yq
    pkgs.dasel
    pkgs.fx
    pkgs.jless
    pkgs.gron
    pkgs.jc
    pkgs.gh
    pkgs.glab
    pkgs.git-lfs
    pkgs.fd
    # ripgrep omitted deliberately: overlays/opencode.nix already prepends
    # self.ripgrep to this PATH, so listing it again is a duplicate entry.
    pkgs.bat
    pkgs.eza
    pkgs.delta
    pkgs.tig
    pkgs.lazygit
    pkgs.fzf
    pkgs.zoxide
    pkgs.atuin
    pkgs.starship
    pkgs.glow
    pkgs.hyperfine
    pkgs.entr
    pkgs.watchexec
    pkgs.just
    pkgs.taskwarrior2
    pkgs.age
    pkgs.sops
    pkgs.rsync
    pkgs.unzip
    pkgs.p7zip
    pkgs.file
    pkgs.ncdu
    pkgs.duf
    pkgs.dust
    pkgs.procs
    pkgs.bandwhich
    pkgs.nmap
    pkgs.mtr
    pkgs.dnsutils
    pkgs.whois
    pkgs.wget
    pkgs.curl
    pkgs.nodejs
    pkgs.uv
    pkgs.tree-sitter
    pkgs.protobuf
    pkgs.buf
    pkgs.grpcurl
    pkgs.websocat
    pkgs.xh
    pkgs.httpie
    # No Kubernetes manifests, .tf files or database work in ~/workspaces
    # (census 2026-10-28) → kubectl/helm/k9s, terraform/terraform-ls/tflint/
    # tfsec, ansible, and the SQL/NoSQL clients were dropped (k9s alone was
    # 228 MiB, terraform+tfsec+tflint 285 MiB). lazysql/sqlit-tui remain in
    # home.packages; re-add a client here only when a project needs it.
    pkgs.act
    pkgs.pre-commit
    pkgs.cue
    pkgs.dhall
    pkgs.nix-tree
    pkgs.nix-diff
    pkgs.nix-index
    pkgs.nix-init
    pkgs.nurl
    pkgs.comma
    pkgs.tealdeer
    pkgs.cheat
    pkgs.gcc
    pkgs.gdb
    pkgs.strace
    pkgs.valgrind
    pkgs.cloc
    pkgs.tokei
    pkgs.visidata
    pkgs.csvtk
    pkgs.miller
    pkgs.python314
  ];
in
  lsps ++ formatters ++ linters ++ security ++ devCli
