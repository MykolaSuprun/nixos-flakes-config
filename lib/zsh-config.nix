{
  settings = {
    keyMap = "viins";
    autocd = true;
    shellAliases = {
      vi = "nvim";
      ls = "eza";
      cat = "bat --theme base16-256";
      nixgc = "nix-collect-garbage";
      confdir = "cd $NIXOS_CONF_DIR";
      editconf = "cd $NIXOS_CONF_DIR; nixvim .";
      nxcnf = "$NIXOS_CONF_DIR/nxcnf.sh";
      spf = "superfile";
    };
    integrations = {
      fzf.enable = true;
      zoxide = {
        enable = true;
        flags = ["--cmd" "cd"];
      };
      starship.enable = true;
    };
    completion = {
      enable = true;
      caseInsensitive = true;
      fuzzySearch = true;
    };
    autoSuggestions = {
      enable = true;
      strategy = ["history" "completion"];
    };
    history = {
      share = true;
      ignoreAllDups = true;
      save = 50000;
      size = 50000;
    };
    env = {
      GPG_TTY = "$(tty)";
      VI_MODE_SET_CURSOR = "true";
      NIXPKGS_ALLOW_UNFREE = "1";
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };

  extraRC = ''
    gpgconf --launch gpg-agent
    eval "$(direnv hook zsh)"
    eval "$(carapace _carapace zsh)"

    # Source local zshrc overrides if present
    if [[ -f ~/.zshrc_lcl ]]; then
      source ~/.zshrc_lcl
    fi
  '';

  extraPackages = pkgs:
    with pkgs; [
      eza
      bat
      gnupg
      direnv
      nix-direnv
      carapace
    ];
}
