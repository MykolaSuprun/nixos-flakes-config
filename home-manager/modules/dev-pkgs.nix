{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: {
  options.myconf.dev.enable = lib.mkEnableOption "development packages";
  config = lib.mkIf config.myconf.dev.enable {
    programs = {
      delta = {
        enable = true;
        enableGitIntegration = true;
      };
      direnv = {
        enable = true;
        enableBashIntegration = true;
        nix-direnv.enable = true;
      };
      gpg.enable = true;
      fzf = {
        enable = true;
      };
      lazygit = {enable = true;};
      superfile = {
        enable = true;
        metadataPackage = pkgs.exiftool;
        firstUseCheck = false;
        settings = {
          theme = "catppuccin-${config.catppuccin.flavor}";
          editor = "nvim";
          dir_editor = "nvim";
          auto_check_update = false;
          cd_on_quit = true;
          default_open_file_preview = true;
          show_image_preview = true;
          show_panel_footer_info = true;
          file_size_use_si = false;
          default_directory = "~";
          file_panel_extra_columns = 2;
          nerdfont = true;
          show_select_icons = true;
          code_previewer = "bat";
          sidebar_width = 20;
          metadata = true;
          zoxide_support = true;
          open_with = {
            # images → gwenview
            png = "gwenview";
            jpg = "gwenview";
            jpeg = "gwenview";
            gif = "gwenview";
            webp = "gwenview";
            svg = "gwenview";
            bmp = "gwenview";
            tiff = "gwenview";
            ico = "gwenview";
            # documents → okular
            pdf = "okular";
            # web → zen-beta
            html = "zen-beta";
            htm = "zen-beta";
            # video → vlc
            mp4 = "vlc";
            mkv = "vlc";
            avi = "vlc";
            webm = "vlc";
            mov = "vlc";
            flv = "vlc";
            # audio → vlc
            mp3 = "vlc";
            flac = "vlc";
            ogg = "vlc";
            wav = "vlc";
            m4a = "vlc";
            opus = "vlc";
            # office → libreoffice
            docx = "libreoffice";
            odt = "libreoffice";
            xlsx = "libreoffice";
            ods = "libreoffice";
            pptx = "libreoffice";
            odp = "libreoffice";
          };
        };
        hotkeys = {
          # Global hotkeys
          confirm = ["enter" ""];
          quit = ["ctrl+c" ""];
          cd_quit = ["Q" ""];
          # Navigation
          list_up = ["k" ""];
          list_down = ["j" ""];
          page_up = ["pgup" ""];
          page_down = ["pgdown" ""];
          # File Panel Controls
          create_new_file_panel = ["n" ""];
          close_file_panel = ["q" ""];
          next_file_panel = ["tab" ""];
          previous_file_panel = ["shift+tab" ""];
          split_file_panel = ["N" ""];
          toggle_file_preview_panel = ["f" ""];
          open_sort_options_menu = ["o" ""];
          toggle_reverse_sort = ["R" ""];
          # Focus Manipulation
          focus_on_process_bar = ["ctrl+p" ""];
          focus_on_sidebar = ["ctrl+s" ""];
          focus_on_metadata = ["ctrl+d" ""];
          # File/Dir Creation/Renaming
          file_panel_item_create = ["a" ""];
          file_panel_item_rename = ["r" ""];
          # Main File Operations
          copy_items = ["y" ""];
          cut_items = ["x" ""];
          paste_items = ["p" ""];
          delete_items = ["d" ""];
          permanently_delete_items = ["D" ""];
          # Archive Manipulation
          extract_file = ["ctrl+e" ""];
          compress_file = ["ctrl+a" ""];
          # Editor Actions
          open_file_with_editor = ["e" ""];
          open_current_directory_with_editor = ["E" ""];
          # Other Actions
          pinned_directory = ["P" ""];
          toggle_dot_file = ["." ""];
          change_panel_mode = ["m" ""];
          open_help_menu = ["?" ""];
          open_spf_prompt = [">" ""];
          open_command_line = [":" ""];
          open_zoxide = ["z" ""];
          copy_path = ["Y" ""];
          copy_present_working_directory = ["c" ""];
          toggle_footer = ["ctrl+f" ""];
          # Typing hotkeys
          confirm_typing = ["enter" ""];
          cancel_typing = ["esc" ""];
          # Normal Mode Actions
          parent_directory = ["-" ""];
          search_bar = ["/" ""];
          # Selection Mode Actions
          file_panel_select_mode_items_select_down = ["J" ""];
          file_panel_select_mode_items_select_up = ["K" ""];
          file_panel_select_all_items = ["A" ""];
        };
      };
      yazi = {
        enable = true;
        enableZshIntegration = true;
        enableBashIntegration = true;
        extraPackages = with pkgs; [
          jq
          fd
          zoxide
          resvg
          imagemagick
          fzf
          poppler
          ffmpeg
          zip
          ripgrep
          resvg
          imagemagick
          wl-clipboard
        ];
        plugins = {
          git = pkgs.yaziPlugins.git;
          sudo = pkgs.yaziPlugins.sudo;
          lsar = pkgs.yaziPlugins.lsar;
          diff = pkgs.yaziPlugins.diff;
          rsync = pkgs.yaziPlugins.rsync;
          piper = pkgs.yaziPlugins.piper;
          mount = pkgs.yaziPlugins.mount;
          lazygit = pkgs.yaziPlugins.lazygit;
          dupes = pkgs.yaziPlugins.dupes;
          chmod = pkgs.yaziPlugins.chmod;
          duckdb = pkgs.yaziPlugins.duckdb;
          yatline = pkgs.yaziPlugins.yatline;
          restore = pkgs.yaziPlugins.restore;
          githead = pkgs.yaziPlugins.githead;
          starship = pkgs.yaziPlugins.starship;
          projects = pkgs.yaziPlugins.projects;
          compress = pkgs.yaziPlugins.compress;
          files = pkgs.yaziPlugins.vcs-files;
          mediainfo = pkgs.yaziPlugins.mediainfo;
          bookmarks = pkgs.yaziPlugins.bookmarks;
          paste = pkgs.yaziPlugins.smart-paste;
          clipboard = pkgs.yaziPlugins.wl-clipboard;
          char = pkgs.yaziPlugins.jump-to-char;
          motions = pkgs.yaziPlugins.relative-motions;
          catppuccin = pkgs.yaziPlugins.yatline-catppuccin;
        };
      };

      zsh.initContent = lib.mkAfter ''
        # Kitty doesn't set TERM_PROGRAM; expose it so tools like superfile detect
        # the kitty graphics protocol even inside tmux
        if [[ -n "$KITTY_WINDOW_ID" && -z "$TERM_PROGRAM" ]]; then
          export TERM_PROGRAM=kitty
        fi

        function spf() {
          local lastdir_file="''${XDG_STATE_HOME:-$HOME/.local/state}/superfile/lastdir"
          if [[ $# -eq 0 && -f "$lastdir_file" ]]; then
            command superfile "$(cat "$lastdir_file")"
          else
            command superfile "$@"
          fi
          if [[ -f "$lastdir_file" ]]; then
            builtin cd "$(cat "$lastdir_file")"
          fi
        }
      '';
    };

    home.packages = with pkgs; [
      # dev tools
      cachix
      inputs.my-nixvim.packages.${pkgs.stdenv.hostPlatform.system}.lazyvim
      inputs.my-nixvim.packages.${pkgs.stdenv.hostPlatform.system}.nixvim
      inputs.my-nixvim.packages.${pkgs.stdenv.hostPlatform.system}.codevim
      inputs.my-nixvim.packages.${pkgs.stdenv.hostPlatform.system}.nvim
      vscode
      neovide
      # mynav
      # sublime4
      # zed-editor
      nvtopPackages.amd
      tree-sitter
      ripgrep
      nodejs
      cargo
      binutils
      openssl
      go
      gcc
      fzf
      tree
      cmake
      gnumake
      git
      git-crypt
      gnupg
      alejandra
      ghc
      usbutils
      pciutils
      lshw-gui
      mesa-demos
      bat
      # nix
      nix-tree
      nix-diff
      nixfmt
      fh
      poppler # pdf preview
      jq
      fd
      zoxide
      resvg
      imagemagick
      comma
      nix-index
      nurl
      nix-init
      nix-direnv
      codecrafters-cli
      netcat
      zip

      # python
      uv

      # terminal utils
      fd
      browsh # tui browser
      gh # Github CLI
      xclip
      sqlcmd
      killall
      bottom
      btop
      lazydocker
      lazysql
    ];
  };
}
