# Wrap opencode so its binary carries a full dev toolbox on PATH — LSPs,
# formatters, linters, security scanners and CLI utilities — without spilling
# any of them into the global environment. opencode's agent spawns these tools
# by name, so they must be reachable from its own wrapper.
#
# The upstream package already wraps the binary with ripgrep; we re-wrap in
# postFixup to prepend our tool set (nested wrappers are fine — each layer
# only prepends PATH).
self: super: let
  # The toolbox opencode's agent can call by name. Grouped by role for
  # readability; the wrapper flattens them into one PATH prefix.
  opencodeTools = pkgs: let
    lsps = [
      pkgs.typescript-language-server
      pkgs.vscode-langservers-extracted # HTML/CSS/JSON
      pkgs.yaml-language-server
      pkgs.lua-language-server
      pkgs.basedpyright
      pkgs.nixd
      pkgs.rust-analyzer
      pkgs.gopls
      pkgs.bash-language-server
      pkgs.taplo # TOML
      pkgs.marksman # Markdown
      pkgs.clang-tools # C/C++
      pkgs.terraform-ls
      pkgs.dockerfile-language-server
      pkgs.zls # Zig
      pkgs.haskell-language-server
      pkgs.elixir-ls
      pkgs.ruby-lsp
      pkgs.solargraph
      pkgs.jsonnet-language-server
      pkgs.kotlin-language-server
      pkgs.metals # Scala
    ];

    formatters = [
      pkgs.alejandra # Nix
      pkgs.prettierd
      pkgs.prettier
      pkgs.ruff # Python
      pkgs.shfmt # Shell
      pkgs.stylua # Lua
      pkgs.go # gofmt
      pkgs.rustfmt
      pkgs.dprint
      pkgs.yamlfmt
      pkgs.cmake-format
      pkgs.biome
      pkgs.fourmolu
      pkgs.ormolu
      pkgs.stylish-haskell
      pkgs.scalafmt
      pkgs.google-java-format
      pkgs.ktlint
      pkgs.csharpier
      pkgs.ocamlformat
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
      pkgs.ansible-lint
      pkgs.tflint
      pkgs.sqlfluff
      pkgs.cppcheck
      pkgs.cpplint
      pkgs.flawfinder # C
      pkgs.phpstan
      pkgs.rubocop
      pkgs.hlint # Haskell
      pkgs.scalafix
      pkgs.swiftlint
      pkgs.checkstyle # Java
      pkgs.pmd # Java
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
      pkgs.semgrep
      pkgs.bandit # Python
      pkgs.pip-audit
      pkgs.cargo-audit
      pkgs.cargo-deny
      pkgs.govulncheck
      pkgs.gosec # Go
      pkgs.revive
      pkgs.trivy
      pkgs.grype
      pkgs.syft # SBOM
      pkgs.osv-scanner
      pkgs.tfsec
      pkgs.kube-linter
      pkgs.kubeconform
      pkgs.conftest
      pkgs.open-policy-agent
      pkgs.nuclei
      pkgs.brakeman # Rails
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
      pkgs.ripgrep
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
      pkgs.kubectl
      pkgs.helm
      pkgs.k9s
      pkgs.terraform
      pkgs.ansible
      pkgs.act
      pkgs.pre-commit
      pkgs.sqlite-interactive
      pkgs.duckdb
      pkgs.pgcli
      pkgs.mycli
      pkgs.litecli
      pkgs.lazysql
      pkgs.valkey
      pkgs.mongosh
      pkgs.jsonnet
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
    lsps ++ formatters ++ linters ++ security ++ devCli;
in {
  opencode = super.opencode.overrideAttrs (oldAttrs: {
    nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [super.makeWrapper];

    postFixup =
      (oldAttrs.postFixup or "")
      + ''
        wrapProgram $out/bin/opencode \
          --prefix PATH : ${super.lib.makeBinPath (opencodeTools super)}
      '';
  });
}
