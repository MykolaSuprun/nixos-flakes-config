{ inputs, pkgs, ... }:
let
  neovim-local = "nix run ~/src/nixvim-config -- ";
  neovim_github = "nix run github:MykolaSuprun/nixvim-config #. -- ";
  conf_root = "$NIXOS_CONF_DIR";
  shell_init = pkgs.writeShellScriptBin "init_shell" ''
    # if [[ $(uname -a | grep arch) ]]
    # then
    #   distrobox-host-exec xhost +local:
    #   xhost +SI:localuser:$USER
    #   #PROMPT="%B%F{47}%n%f%b%B:%b%B%F{39}%m%f%b%B>%b "
    #   alias vi="nvim"
    #   alias vim="${neovim-local}"
    #   alias nano="nvim"
    #   alias tmux='tmux -2'
    #   alias steamtinkerlaunch=/home/mykolas/.steam/root/compatibilitytools.d/SteamTinkerLaunch
    #   clear
    # fi
    export GPG_TTY=$(tty)
    gpgconf --launch gpg-agent
    export VI_MODE_SET_CURSOR=true
    export NIXPKGS_ALLOW_UNFREE=1
    export confdir=${conf_root}
    export EDITOR=nvim
    export VISUAL=nvim

    # Aliases
    alias editconf="cd $confdir; nvim ."
    alias nxcnf="$confdir/nxcnf.sh"
    alias nixos-build="$confdir/scripts/nixos-build.sh"
    alias nix-update="cd $confdir; nix flake update --accept-flake-config; cd -"
    alias confdir="cd $confdir"
    alias nixgc="nix-collect-garbage"
    alias arch-build="$confdir/home/mykolas/distrobox/build-arch.sh"
    alias arch="distrobox-enter arch"
    alias vim="${neovim_github}"
    alias nv="${neovim-local}"
    alias vi="nvim"
    alias tmux="tmux -2"
    alias ls="eza"

    # hook direnv
    # eval "$(direnv hook zsh)"
  '';
  tmux_init = pkgs.writeShellScriptBin "start_tmux" ''
    if tmux run 2>/dev/null; then
      echo "Tmux server is running:"
      exec tmux list-sessions -F '#S' | fzf --reverse | xargs tmux switch-client -t
    else
        echo "Tmux server is not running:"
        exec tmux new-session -s home
    fi
  '';
  fish_init = pkgs.writeShellScriptBin "init_fish" ''
    #!/usr/bin/env fish
    source ${shell_init}/bin/init_shell

    # Emulates vim's cursor shape behavior
    # Set the normal and visual mode cursors to a block
    set fish_cursor_default block
    # Set the insert mode cursor to a line
    set fish_cursor_insert line
    # Set the replace mode cursors to an underscore
    set fish_cursor_replace_one underscore
    set fish_cursor_replace underscore
    # Set the external cursor to a line. The external cursor appears when a command is started.
    # The cursor shape takes the value of fish_cursor_default when fish_cursor_external is not specified.
    set fish_cursor_external line
    # The following variable can be used to configure cursor shape in
    # visual mode, but due to fish_cursor_default, is redundant here
    set fish_cursor_visual block
    set fish_vi_key_bindings --no-erase insert

    fish_vi_key_bindings

    # if status is-interactive
    # and not set -q TMUX
    #     if tmux has-session -t home
    #       read -l -P 'Attach to home? [Y/n] ' confirm
    #       switch $confirm
    #         case "" Y y
    #           exec tmux attach-session -t home
    #         case N n
    #           exec tmux new-session
    #       end
    # return 1
    #     else
    #         tmux new-session -s home
    #     end
    # end
  '';
in {
  home.packages = with pkgs; [ babelfish grc ];

  programs = {
    nushell = {
      enable = true;
      envFile.source = ./../configurations/mykolas/nushell/env.nu;
      configFile.source = ./../configurations/mykolas/nushell/config.nu;
    };
    fish = {
      enable = true;
      plugins = [
        {
          name = "puffer";
          src = pkgs.fishPlugins.puffer.src;
        }
        {
          name = "sponge";
          src = pkgs.fishPlugins.sponge.src;
        }
        {
          name = "tide";
          src = pkgs.fishPlugins.tide.src;
        }
        {
          name = "grc";
          src = pkgs.fishPlugins.grc.src;
        }
        {
          name = "fzf-fish";
          src = pkgs.fishPlugins.fzf-fish.src;
        }
        {
          name = "forgit";
          src = pkgs.fishPlugins.forgit.src;
        }
        {
          name = "colored-man-pages";
          src = pkgs.fishPlugins.colored-man-pages.src;
        }
        {
          name = "bass";
          src = pkgs.fishPlugins.bass.src;
        }
        {
          name = "autopair";
          src = pkgs.fishPlugins.autopair.src;
        }
      ];
      interactiveShellInit = ''
        source ${fish_init}/bin/init_fish
        # if status is-interactive
        #     and not set -q TMUX
        #         ${tmux_init}/bin/start_tmux
        # end
      '';
    };
    bash = {
      enable = true;
      enableCompletion = true;
      initExtra = ''
        ${shell_init}
        if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
          then
            shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
            exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
          fi
      '';
    };
  };
}
