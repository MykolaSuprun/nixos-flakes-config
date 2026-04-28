{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: let
  zshConfig = import ../../lib/zsh-config.nix;

  shell_init = pkgs.writeShellScriptBin "init_shell" (
    builtins.concatStringsSep "\n" (
      builtins.attrValues (builtins.mapAttrs (k: v: "export ${k}=${v}") zshConfig.settings.env)
    )
    + "\n"
    + builtins.concatStringsSep "\n" (
      builtins.attrValues (builtins.mapAttrs (k: v: "alias ${k}=${builtins.toJSON v}") zshConfig.settings.shellAliases)
    )
  );

  conn-win = pkgs.writeShellScriptBin "conn-win" ''
        sdl-freerdp /v:localhost:3389 /u:VM /size:1920x1080 /sound \
      /gfx:AVC444,mask:0xFFFFFFFF /bpp:32 /gdi:hw /network:lan -compression \
      +aero +menu-anims +window-drag +clipboard -grab-keyboard -grab-mouse \
      /cert:ignore /sec:nla:off
  '';

  win11 = pkgs.writeShellScriptBin "win11" ''
    docker compose -f $NIXOS_CONF_DIR/windows-containers/win_11_bacis.yaml up
  '';
  py-init = pkgs.writeShellScriptBin "py-init" ''
    git init

    cat > flake.nix << 'EOF'
    {
      description = "Python development environment with uv";

      inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        flake-utils.url = "github:numtide/flake-utils";
      };

      outputs = {
        self,
        nixpkgs,
        flake-utils,
      }:
        flake-utils.lib.eachDefaultSystem (
          system: let
            pkgs = nixpkgs.legacyPackages.''${system};
          in {
            devShells.default = pkgs.mkShell {
              buildInputs = with pkgs; [
                uv
                python312
              ];

              shellHook = '''
                echo "UV Python environment activated"
                uv --version
                python --version
              ''';
            };
          }
        );
    }
    EOF

    git add .
    nix develop
  '';
in {
  options.myconf.shell.enable = lib.mkEnableOption "shell configuration";
  config = lib.mkIf config.myconf.shell.enable {
  home.packages = with pkgs; [
    babelfish
    grc

    conn-win
    win11
    py-init
  ];

  programs = {
    nushell = {
      enable = true;
      envFile.source = ./../users/mykolas/config/nushell/env.nu;
      configFile.source = ./../users/mykolas/config/nushell/config.nu;
    };
    carapace = {
      enable = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
      enableBashIntegration = true;
    };
    fzf = {
      enable = true;
      tmux.enableShellIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
      enableBashIntegration = true;
    };
    starship = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
      enableNushellIntegration = true;
      enableTransience = true;
    };
    zoxide = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
      enableNushellIntegration = true;
      options = [
        "--cmd cd"
      ];
    };
    direnv = {
      enableZshIntegration = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
    };
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      defaultKeymap = "viins";
      initContent = ''
        source ${shell_init}/bin/init_shell
        ${zshConfig.extraRC}
      '';
      antidote = {
        enable = true;
        plugins = [
          "jeffreytse/zsh-vi-mode"
        ];
      };
    };
  };
  };
}
