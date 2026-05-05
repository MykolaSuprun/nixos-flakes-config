{
  description = "Python development environment with uv";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
      perSystem = {system, ...}: let
        pkgs = inputs.nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            uv
            python313
          ];

          shellHook = ''
            export UV_PYTHON="${pkgs.python313}/bin/python"
            if [ ! -f .venv/pyvenv.cfg ]; then
              echo ">>> Creating uv virtual environment..."
              uv venv
            fi
            source .venv/bin/activate
            echo "Python $(python --version) | uv $(uv --version)"
          '';
        };
      };
    };
}
