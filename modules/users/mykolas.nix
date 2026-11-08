# Primary user — settings shared by every host. Host-only differences live in
# modules/hosts/<host>/home.nix; desktop-only bits in modules/desktop/core.
_: {
  flake.modules.homeManager.user = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.myconf.gpg.pinentry = lib.mkOption {
      type = lib.types.package;
      default = pkgs.pinentry-qt;
      defaultText = lib.literalExpression "pkgs.pinentry-qt";
      description = "Pinentry used by gpg-agent (pinentry-qt works on Wayland).";
    };

    config = {
      home = {
        username = "mykolas";
        homeDirectory = "/home/mykolas";
        sessionVariables = {
          NIXOS_CONF_DIR = lib.mkDefault "${config.home.homeDirectory}/workspaces/src/nixconf";
          NH_FLAKE = lib.mkDefault config.home.sessionVariables.NIXOS_CONF_DIR;
        };
      };

      programs.home-manager.enable = true;
      xdg.enable = true;

      # gpg-agent is the single SSH agent on every host (NixOS ssh-agent is off).
      services.gpg-agent = {
        enable = true;
        enableSshSupport = true;
        grabKeyboardAndMouse = true;
        pinentry.package = config.myconf.gpg.pinentry;
        defaultCacheTtl = 86400; # 24 hours
        defaultCacheTtlSsh = 86400; # 24 hours
        maxCacheTtl = 604800; # 7 days
        maxCacheTtlSsh = 604800; # 7 days
        # TTY passphrase prompts when no display is available (SSH, bare TTY).
        extraConfig = ''
          allow-loopback-pinentry
        '';
      };
    };
  };
}
