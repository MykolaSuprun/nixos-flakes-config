_: {
  flake.modules.nixos.sys-pkgs = {
    pkgs,
    config,
    lib,
    ...
  }: {
    options.myconf.nixos.syspkgs.enable = lib.mkEnableOption "system utility packages (nh, eza, fzf, etc.)";

    config = lib.mkIf config.myconf.nixos.syspkgs.enable {
      programs = {
        nh = {
          enable = true;
          clean.enable = true;
          clean.extraArgs = "--keep-since 10d --keep 10";
        };
        usbtop.enable = true;
      };

      environment.systemPackages = with pkgs; [
        nix-output-monitor
        nvd
        eza
        fzf
        xclip
        tree
        ripgrep
        git
        git-crypt
        gnupg
        fd
        bat
        fh
        lf
        killall
        bottom
        # Flake-managed NixOS tooling (available system-wide on all hosts)
        pkgs.nixconf.nixos-build
        pkgs.nixconf.nixos-check
        pkgs.nixconf.nixos-install
        pkgs.nixconf.nixos-iso
        pkgs.nixconf.nixos-flash
      ];
    };
  };
}
