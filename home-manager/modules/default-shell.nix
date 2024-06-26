{inputs, ...}: let
  neovim-local = "nix run ~/src/nixvim-config -- ";
  neovim_github = "nix run github:MykolaSuprun/nixvim-config #. -- ";
  conf_root = "~/.nixconf";
  shell_init = ''
    if [[ $(uname -a | grep arch) ]]
    then
      distrobox-host-exec xhost +local:
      xhost +SI:localuser:$USER
      #PROMPT="%B%F{47}%n%f%b%B:%b%B%F{39}%m%f%b%B>%b "
      alias vi="nvim"
      alias vim="${neovim-local}"
      alias nano="nvim"
      alias tmux='tmux -2'
      alias steamtinkerlaunch=/home/mykolas/.steam/root/compatibilitytools.d/SteamTinkerLaunch
      clear
    fi
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
    alias nixos-build="$confdir/nxcnf.sh build os geks-nixos"
    alias exmnt="$confdir/home-manager/configurations/mykolas/scripts/mount_ext_ssd.sh"
    alias home-build="$confdir/nxcnf.sh build home"
    alias nix-update="$confdir/nxcnf.sh update"
    alias confdir=$confdir
    alias nixgc="nix-collect-garbage"
    alias arch-build="$confdir/home/mykolas/distrobox/build-arch.sh"
    alias arch="distrobox-enter arch"
    alias vim="${neovim_github}"
    alias nv="${neovim-local}"
    alias vi="nvim"
    alias tmux="tmux -2"

    if command -v tmux &> /dev/null && [ -n "$PS1" ] && \
    [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]; then
      exec tmux
    fi

    # hook direnv
    # eval "$(direnv hook zsh)"
  '';
in {
  programs = {
    zsh = {
      enable = true;
      initExtra = ''
        ${shell_init}
      '';
      oh-my-zsh = {
        enable = true;
        theme = "agnoster";
        plugins = [
          "git"
          "cp"
          "aliases"
          "branch"
          "cabal"
          "docker"
          "python"
          "scala"
          "sbt"
          "stack"
          "sublime"
          "sudo"
          "systemd"
          "zsh-interactive-cd"
          "vi-mode"
          "archlinux"
        ];
      };
    };

    bash = {
      enable = true;
      enableCompletion = true;
      bashrcExtra = ''
        ${shell_init}
      '';
    };
  };
}
