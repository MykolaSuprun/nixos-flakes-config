{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: {
  options.myconf.git.enable = lib.mkEnableOption "git configuration";

  config = lib.mkIf config.myconf.git.enable {
    programs.git = {
      enable = true;

      # Use the new unified `settings` API (replaces userName, userEmail,
      # aliases, extraConfig in newer Home Manager versions).
      settings = {
        user = {
          name = "Mykola Suprun";
          email = "mykola.suprun@protonmail.com";
        };

        core.editor = "nvim";

        # Delta options live in programs.delta.options below; core.pager and
        # interactive.diffFilter come from programs.delta.enableGitIntegration
        # (dev-pkgs.nix). Do NOT duplicate delta.* keys here.

        merge.conflictstyle = "zdiff3";
        merge.tool = "nvimdiff";

        "mergetool \"nvimdiff\"".cmd =
          "nvim -d $LOCAL $REMOTE $MERGED -c '$wincmd w' -c 'wincmd J'";

        gpg.program = "gpg";

        pull.rebase = false;

        github.user = "MykolaSuprun";

        # Use the default browser (resolved from $BROWSER) for git's web-based
        # commands like `git instaweb` and `git help --web`.
        web.browser = ''"$(basename "$BROWSER")"'';
        help.format = "web";

        color.ui = "auto";

        alias.logs = "log --show-signature";

        # GitHub credential helper via `gh auth git-credential`
        credential."https://github.com" = {
          helper = [
            "" # Clear any inherited helpers first
            "!gh auth git-credential"
          ];
        };
        credential."https://gist.github.com" = {
          helper = [
            ""
            "!gh auth git-credential"
          ];
        };
      };

      # Git LFS support
      lfs.enable = true;

      # Sign commits with GPG (currently disabled — set signByDefault = true to enable)
      signing = {
        key = null; # Uses default GPG key
        signByDefault = false;
      };
    };

    # Delta integration — ensures git uses delta as pager/diffFilter.
    # Note: core.pager and interactive.diffFilter are automatically set by
    # programs.delta.enableGitIntegration (enabled in dev-pkgs.nix).
    programs.delta = {
      enable = true;
      options = {
        navigate = true;
        "side-by-side" = true;
      };
    };
  };
}

